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
    ];
    text = ''
      set -uo pipefail

      day=${toString cfg.day}
      night=${toString cfg.night}
      day_elev=${toString cfg.dayElevation}
      night_elev=${toString cfg.nightElevation}
      cache=/run/monitor-brightness.last

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

      # ddcutil writes are slow and the panel is already at the right level
      # most of the time -- skip the I2C traffic when nothing changed.
      if [ "$(cat "$cache" 2>/dev/null)" = "$target" ]; then
        exit 0
      fi

      displays=$(ddcutil detect --brief 2>/dev/null \
        | grep '^Display' \
        | awk '{print $2}')

      if [ -z "$displays" ]; then
        echo "no DDC/CI capable displays detected" >&2
        exit 1
      fi

      # Each display is its own I2C bus, so drive them concurrently --
      # sequential ddcutil writes across three panels are visibly staggered.
      set_one() {
        local d="$1"
        for _ in 1 2 3; do
          if ddcutil --display "$d" \
               --sleep-multiplier ${toString cfg.sleepMultiplier} \
               setvcp 10 "$target" 2>/dev/null; then
            return 0
          fi
          sleep 1
        done
        echo "display $d: failed to set brightness after 3 attempts" >&2
        return 1
      }

      rc=0
      pids=""
      for d in $displays; do
        set_one "$d" &
        pids="$pids $!"
      done
      for p in $pids; do
        wait "$p" || rc=1
      done

      # Only cache on full success, so a partial failure retries next tick.
      if [ "$rc" = 0 ]; then
        echo "$target" > "$cache"
        echo "brightness -> $target%"
      fi
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
