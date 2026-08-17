# Schedules monitor backlight brightness via DDC/CI so you don't have to
# poke the OSD every evening. Drives the real backlight (VCP feature 0x10)
# over the video cable, not compositor gamma — so it actually reduces light
# output rather than just making things look darker.
#
# Requires DDC/CI to be enabled in each monitor's OSD (usually Others >
# DDC/CI). Add `./modules/monitor-brightness.nix` to imports.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.monitor-brightness;

  # ddcutil is flaky over DisplayPort on some GPU/monitor combinations, so
  # each write is retried before giving up. A failure on one display must
  # not abort the others — a dead monitor shouldn't leave the rest at the
  # wrong brightness.
  setScript = pkgs.writeShellApplication {
    name = "monitor-brightness-set";
    runtimeInputs = [
      pkgs.ddcutil
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnugrep
    ];
    text = ''
      set -uo pipefail

      value="''${1:?usage: monitor-brightness-set <0-100>}"

      displays=$(ddcutil detect --brief 2>/dev/null \
        | grep '^Display' \
        | awk '{print $2}')

      if [ -z "$displays" ]; then
        echo "no DDC/CI capable displays detected" >&2
        exit 1
      fi

      rc=0
      for d in $displays; do
        for attempt in 1 2 3; do
          if ddcutil --display "$d" \
               --sleep-multiplier ${toString cfg.sleepMultiplier} \
               setvcp 10 "$value" 2>/dev/null; then
            echo "display $d -> $value%"
            break
          fi
          if [ "$attempt" = 3 ]; then
            echo "display $d: failed to set brightness after 3 attempts" >&2
            rc=1
          fi
          sleep 1
        done
      done
      exit "$rc"
    '';
  };

  mkPhase = name: phaseCfg: {
    "monitor-brightness-${name}" = {
      description = "Set monitor brightness for ${name}";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe setScript} ${toString phaseCfg.brightness}";
      };
    };
  };

  mkTimer = name: phaseCfg: {
    "monitor-brightness-${name}" = {
      description = "Schedule monitor brightness for ${name}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = phaseCfg.time;
        # Catch up after suspend or a machine that was off at the trigger
        # time — otherwise an evening reboot leaves you at day brightness.
        Persistent = true;
      };
    };
  };

  phaseOption =
    { defaultBrightness, defaultTime }:
    lib.mkOption {
      type = lib.types.submodule {
        options = {
          brightness = lib.mkOption {
            type = lib.types.ints.between 0 100;
            default = defaultBrightness;
            description = "Backlight brightness percentage.";
          };
          time = lib.mkOption {
            type = lib.types.str;
            default = defaultTime;
            description = "systemd OnCalendar expression for when to apply.";
          };
        };
      };
      default = { };
      description = "Brightness and schedule for this phase.";
    };
in
{
  options.services.monitor-brightness = {
    enable = lib.mkEnableOption "scheduled DDC/CI monitor brightness";

    day = phaseOption {
      defaultBrightness = 60;
      defaultTime = "07:00";
    };

    night = phaseOption {
      defaultBrightness = 20;
      defaultTime = "19:00";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "me";
      description = ''
        User to add to the i2c group, so ddcutil can be run by hand without
        sudo for one-off adjustments.
      '';
    };

    sleepMultiplier = lib.mkOption {
      type = lib.types.float;
      default = 0.5;
      description = ''
        ddcutil I2C timing multiplier. Lower is faster but more likely to
        fail on marginal links; raise towards 1.0 or above if writes are
        unreliable.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.i2c.enable = true;

    users.users.${cfg.user}.extraGroups = [ "i2c" ];

    environment.systemPackages = [
      pkgs.ddcutil
      setScript
    ];

    systemd.services = mkPhase "day" cfg.day // mkPhase "night" cfg.night;
    systemd.timers = mkTimer "day" cfg.day // mkTimer "night" cfg.night;
  };
}
