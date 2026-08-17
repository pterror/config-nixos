{ pkgs, ... }:
# Blanks the monitors via DPMS instead of reaching for their power buttons.
# DPMS (rather than DDC `setvcp d6`) because many monitors will power off
# over DDC but refuse to come back on — their DDC controller sleeps with
# the panel. Dropping the signal avoids that entirely.
#
# hyprctl is resolved from PATH: hypridle is exec-once'd by Hyprland, so it
# inherits the session environment where hyprland is already on PATH.
''
  general {
    # Suspend/resume can leave outputs blanked — force them back on.
    after_sleep_cmd = hyprctl dispatch dpms on
  }

  listener {
    timeout = 600
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
  }
''
