# Keeps chosen windows rendering while the monitors are blanked.
#
# Hyprland stops delivering frame callbacks to DPMS-off outputs, which
# stalls anything driven by them -- games, video, requestAnimationFrame.
# Switching a monitor off by its physical button does not do this, because
# the compositor still considers the output connected. This module gets
# that behaviour from software: on idle it parks each monitor's active
# workspace on a headless output, then blanks the real panels.
#
# An output only renders its *active* workspace, so one headless output is
# created per real monitor rather than parking everything on a single one.
#
# Parking happens when either:
#   - keep-alive mode was armed by hand (headless-arm), or
#   - a window matches `matchClasses` / `matchExePatterns`.
# Otherwise idle does a plain DPMS off.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.headless-idle;

  armState = ''"''${XDG_RUNTIME_DIR:-/tmp}/headless-arm"'';
  parkState = ''"''${XDG_RUNTIME_DIR:-/tmp}/headless-parked"'';

  classArray = lib.concatMapStringsSep " " lib.escapeShellArg cfg.matchClasses;
  patternArray = lib.concatMapStringsSep " " lib.escapeShellArg cfg.matchExePatterns;

  mkScript =
    name: text:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        pkgs.jq
        pkgs.coreutils
      ];
      inherit text;
    };

  # Shared helpers, inlined into each script that needs them.
  common = ''
    real_monitors() {
      hyprctl monitors -j | jq -r '.[] | select(.name | startswith("HEADLESS-") | not) | .name'
    }

    headless_names() {
      hyprctl monitors -j | jq -r '.[] | select(.name | startswith("HEADLESS-")) | .name'
    }

    active_workspace_on() {
      hyprctl monitors -j | jq -r --arg m "$1" '.[] | select(.name == $m) | .activeWorkspace.id'
    }
  '';

  parkScript = mkScript "headless-park" ''
    set -uo pipefail
    ${common}

    park=${parkState}
    [ -f "$park" ] && exit 0   # already parked

    : > "$park"
    for mon in $(real_monitors); do
      ws=$(active_workspace_on "$mon")
      [ -n "$ws" ] || continue

      before=$(headless_names | sort | tr '\n' ' ')
      hyprctl output create headless >/dev/null
      # Identify the new output by set difference -- creation does not
      # report the name it picked.
      new=""
      for h in $(headless_names); do
        case " $before " in
          *" $h "*) ;;
          *) new="$h" ;;
        esac
      done
      if [ -z "$new" ]; then
        echo "failed to create headless output for $mon" >&2
        continue
      fi

      hyprctl keyword monitor "$new,${cfg.headlessMode},auto,1" >/dev/null
      hyprctl dispatch moveworkspacetomonitor "$ws $new" >/dev/null
      printf '%s %s %s\n' "$new" "$ws" "$mon" >> "$park"
    done

    # Blank each real panel by name: a bare `dpms off` would also blank the
    # headless outputs, defeating the point.
    for mon in $(real_monitors); do
      hyprctl dispatch dpms off "$mon" >/dev/null
    done
  '';

  restoreScript = mkScript "headless-restore" ''
    set -uo pipefail
    ${common}

    park=${parkState}

    for mon in $(real_monitors); do
      hyprctl dispatch dpms on "$mon" >/dev/null
    done

    [ -f "$park" ] || exit 0

    while read -r headless ws orig; do
      [ -n "$headless" ] || continue
      hyprctl dispatch moveworkspacetomonitor "$ws $orig" >/dev/null
      hyprctl output remove "$headless" >/dev/null
    done < "$park"

    rm -f "$park"
  '';

  shouldParkScript = mkScript "headless-should-park" ''
    set -uo pipefail

    [ -f ${armState} ] && exit 0

    classes=(${classArray})
    patterns=(${patternArray})

    if [ ''${#classes[@]} -gt 0 ]; then
      while read -r c; do
        for want in "''${classes[@]}"; do
          [ "$c" = "$want" ] && exit 0
        done
      done < <(hyprctl clients -j | jq -r '.[].class')
    fi

    if [ ''${#patterns[@]} -gt 0 ]; then
      while read -r pid; do
        [ -n "$pid" ] || continue
        exe=$(readlink -f "/proc/$pid/exe" 2>/dev/null) || continue
        for pat in "''${patterns[@]}"; do
          case "$exe" in
            *"$pat"*) exit 0 ;;
          esac
        done
      done < <(hyprctl clients -j | jq -r '.[].pid')
    fi

    exit 1
  '';

  idleScript = mkScript "headless-idle" ''
    set -uo pipefail

    if headless-should-park; then
      headless-park
    else
      hyprctl dispatch dpms off >/dev/null
    fi
  '';

  resumeScript = mkScript "headless-resume" ''
    set -uo pipefail

    if [ -f ${parkState} ]; then
      headless-restore
    else
      hyprctl dispatch dpms on >/dev/null
    fi
  '';

  dpmsToggleScript = mkScript "headless-dpms-toggle" ''
    set -uo pipefail

    # If windows are parked, the useful action is always to bring them
    # back -- otherwise this key would blank monitors that are already off
    # and strand the workspaces on headless outputs.
    if [ -f ${parkState} ]; then
      headless-restore
    else
      hyprctl dispatch dpms toggle >/dev/null
    fi
  '';

  armScript = mkScript "headless-arm" ''
    set -uo pipefail

    arm=${armState}

    # Disarming while parked should also bring the workspaces back, so this
    # key is always a way out of headless mode.
    if [ -f "$arm" ]; then
      rm -f "$arm"
      [ -f ${parkState} ] && headless-restore
      echo "keep-alive disarmed"
    else
      : > "$arm"
      echo "keep-alive armed"
    fi
  '';
in
{
  options.services.headless-idle = {
    enable = lib.mkEnableOption "parking windows on headless outputs when idle";

    matchClasses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "steam_app_default" ];
      description = ''
        Window classes that should keep rendering while the monitors are
        blanked. Exact match against Hyprland's reported class.
      '';
    };

    matchExePatterns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "steamapps" ];
      description = ''
        Substrings matched against each window's resolved executable path.
        The default catches Steam games. Note Proton titles run under a
        wrapper and browser-based games will not match at all -- arm by
        hand for those.
      '';
    };

    headlessMode = lib.mkOption {
      type = lib.types.str;
      default = "1920x1080@60";
      description = ''
        Mode for the created headless outputs. Should match the real
        panels, or parked windows resize.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      parkScript
      restoreScript
      shouldParkScript
      idleScript
      resumeScript
      dpmsToggleScript
      armScript
    ];
  };
}
