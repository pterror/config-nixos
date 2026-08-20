# Tracks monitor backlight to the sun via DDC/CI, so brightness ramps
# through dusk and dawn instead of stepping at fixed times.
#
# Brightness is interpolated from the sun's elevation angle rather than
# from clock times: above `dayElevation` it sits at `day`, below
# `nightElevation` at `night`, and in between it scales linearly. That
# tracks the seasons on its own -- no sunrise table to maintain, and no
# DST handling (irrelevant in Brisbane, but free anyway).
#
# Requires DDC/CI enabled in each monitor's OSD.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.monitor-brightness;

  # Low-precision solar position (NOAA), accurate to well under a degree --
  # far tighter than backlight steps can resolve.
  elevationScript = pkgs.writers.writePython3 "solar-elevation" { } ''
    import math
    import sys
    from datetime import datetime, timezone

    lat = float(sys.argv[1])
    lon = float(sys.argv[2])

    now = datetime.now(timezone.utc)
    j2000 = datetime(2000, 1, 1, 12, tzinfo=timezone.utc)
    n = (now - j2000).total_seconds() / 86400.0

    mean_lon = (280.460 + 0.9856474 * n) % 360
    mean_anom = math.radians((357.528 + 0.9856003 * n) % 360)
    ecl_lon = math.radians(
        mean_lon + 1.915 * math.sin(mean_anom) + 0.020 * math.sin(2 * mean_anom)
    )
    obliq = math.radians(23.439 - 0.0000004 * n)

    decl = math.asin(math.sin(obliq) * math.sin(ecl_lon))
    right_asc = math.atan2(math.cos(obliq) * math.sin(ecl_lon), math.cos(ecl_lon))

    gmst = (18.697374558 + 24.06570982441908 * n) % 24
    lmst = (gmst + lon / 15.0) % 24
    hour_angle = math.radians(lmst * 15.0 - math.degrees(right_asc))

    lat_r = math.radians(lat)
    elev = math.asin(
        math.sin(lat_r) * math.sin(decl)
        + math.cos(lat_r) * math.cos(decl) * math.cos(hour_angle)
    )
    print(f"{math.degrees(elev):.4f}")
  '';

  applyScript = pkgs.writeShellApplication {
    name = "monitor-brightness-apply";
    runtimeInputs = [
      pkgs.ddcutil
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.util-linux
    ];
    text = ''
      set -uo pipefail

      day=${toString cfg.day}
      night=${toString cfg.night}
      day_elev=${toString cfg.dayElevation}
      night_elev=${toString cfg.nightElevation}
      cachedir=/run/monitor-brightness

      # Monitors reset to their own stored brightness across a power cycle,
      # so after resume the cache is stale and must be bypassed.
      force=0
      if [ "''${1:-}" = "--force" ]; then
        force=1
        shift
      fi

      if [ $# -ge 1 ]; then
        # Explicit override, e.g. `monitor-brightness-apply 40`.
        target="$1"
      else
        elev=$(${elevationScript} ${toString cfg.latitude} ${toString cfg.longitude})
        target=$(awk -v e="$elev" -v d="$day" -v n="$night" \
                     -v de="$day_elev" -v ne="$night_elev" \
          'BEGIN {
             if (e >= de)      { v = d }
             else if (e <= ne) { v = n }
             else              { v = n + (e - ne) / (de - ne) * (d - n) }
             printf "%d", (v < 0 ? 0 : (v > 100 ? 100 : v + 0.5))
           }')
      fi

      # Created by tmpfiles as 1777; umask 000 keeps the files group-writable
      # so root timer runs and ad-hoc user runs share one view of state.
      # Split state would reintroduce exactly the drift this cache prevents.
      umask 000
      mkdir -p "$cachedir"

      # Only one run at a time. The timer tick, hypridle's on-resume, the
      # post-suspend service and a manual invocation can all fire at once,
      # and concurrent DDC traffic has been observed to hang the amdgpu SMU.
      # flock rather than a pid file: the kernel drops it when the process
      # dies, so a crashed run cannot wedge every later one.
      exec 9>"$cachedir/.lock"
      if ! flock -w 15 9; then
        echo "another run holds the lock, skipping" >&2
        exit 0
      fi

      # One detect for the whole run, capturing the I2C bus number. Writes
      # then use --bus, which addresses the bus directly: every
      # `ddcutil --display N` invocation instead re-scans *all* buses via
      # ddc_detect_all_displays, so per-display calls multiply I2C traffic
      # by the display count.
      records=$(ddcutil detect --brief 2>/dev/null | awk '
        /I2C bus:/       { bus = $NF; sub(/.*i2c-/, "", bus) }
        /DRM connector:/ { conn = $NF }
        /Monitor:/       { print bus "|" conn }
      ')

      if [ -z "$records" ]; then
        echo "no DDC/CI capable displays detected" >&2
        exit 1
      fi

      # Each display caches its own last-applied value. A single shared
      # cache is unsafe: if one panel is missed on a tick -- detect not
      # listing it, or its write failing -- the others still succeed, the
      # shared value is written, and every later tick short-circuits on it,
      # freezing the missed panel at a stale brightness indefinitely.
      #
      # Writes are sequential, deliberately. Running them concurrently does
      # not help: ddcutil takes an flock per bus, so concurrent instances
      # serialise anyway, and the contention is actively harmful -- enough
      # of it has been observed to hang the amdgpu SMU, taking the GPU down
      # with it. Using --bus keeps each write to a single bus.
      set_one() {
        local bus="$1" conn="$2" cachefile
        cachefile="$cachedir/''${conn:-bus$bus}"

        if [ "$force" = 0 ] && [ "$(cat "$cachefile" 2>/dev/null)" = "$target" ]; then
          return 0
        fi

        for _ in 1 2 3; do
          if ddcutil --bus "$bus" \
               --sleep-multiplier ${toString cfg.sleepMultiplier} \
               setvcp 10 "$target" 2>/dev/null; then
            echo "$target" > "$cachefile"
            return 0
          fi
          sleep 1
        done
        # Leave the cache untouched so the next tick retries this panel.
        echo "bus $bus ($conn): failed to set brightness after 3 attempts" >&2
        return 1
      }

      rc=0
      while IFS='|' read -r bus conn; do
        [ -n "$bus" ] || continue
        set_one "$bus" "$conn" || rc=1
      done <<< "$records"

      exit "$rc"
    '';
  };
in
{
  options.services.monitor-brightness = {
    enable = lib.mkEnableOption "solar-tracked DDC/CI monitor brightness";

    day = lib.mkOption {
      type = lib.types.ints.between 0 100;
      default = 60;
      description = "Brightness percentage with the sun high.";
    };

    night = lib.mkOption {
      type = lib.types.ints.between 0 100;
      default = 0;
      description = "Brightness percentage after dark.";
    };

    dayElevation = lib.mkOption {
      type = lib.types.number;
      default = 10.0;
      description = ''
        Sun elevation in degrees at or above which full day brightness is
        used. The ramp finishes here.
      '';
    };

    nightElevation = lib.mkOption {
      type = lib.types.number;
      default = -6.0;
      description = ''
        Sun elevation in degrees at or below which night brightness is
        used. -6 is the end of civil twilight.
      '';
    };

    latitude = lib.mkOption {
      type = lib.types.number;
      default = -27.5;
      description = "Latitude in decimal degrees, north positive.";
    };

    longitude = lib.mkOption {
      type = lib.types.number;
      default = 153.0;
      description = "Longitude in decimal degrees, east positive.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "*:0/5";
      description = ''
        systemd OnCalendar expression controlling how often brightness is
        recomputed. Shorter intervals give a smoother ramp at the cost of
        more I2C traffic; writes are skipped when the value is unchanged.
      '';
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

    systemd.tmpfiles.rules = [ "d /run/monitor-brightness 1777 root root -" ];

    users.users.${cfg.user}.extraGroups = [ "i2c" ];

    environment.systemPackages = [
      pkgs.ddcutil
      applyScript
    ];

    systemd.services.monitor-brightness = {
      description = "Track monitor brightness to solar elevation";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyScript;
      };
    };

    # The timer alone is not enough: monitors come back from suspend at
    # their own stored brightness, and a resume between ticks would leave
    # them wrong for up to a full interval.
    systemd.services.monitor-brightness-resume = {
      description = "Reapply monitor brightness after resume";
      after = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];
      wantedBy = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];
      serviceConfig = {
        Type = "oneshot";
        # Panels need a moment to finish waking before they answer on I2C.
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
        ExecStart = "${lib.getExe applyScript} --force";
      };
    };

    systemd.timers.monitor-brightness = {
      description = "Recompute monitor brightness";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.interval;
        OnBootSec = "1min";
        Persistent = true;
      };
    };
  };
}
