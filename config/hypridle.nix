{ pkgs, ... }:
# Idle handling. Rather than a bare DPMS off, this defers to
# headless-idle (modules/headless-idle.nix), which decides whether to
# park windows on headless outputs first -- see that module for why.
''
  general {
    # Suspend/resume can leave outputs blanked -- force them back on.
    after_sleep_cmd = headless-resume
  }

  listener {
    timeout = 600
    on-timeout = headless-idle
    # The timer keeps ticking while blanked, but a monitor in standby may
    # not answer on I2C -- in which case the cache holds the pre-blank
    # value and the panels come back at the wrong brightness for up to a
    # full interval. Recomputing here costs nothing when it is already
    # correct: the cache check short-circuits before any I2C traffic.
    on-resume = headless-resume; monitor-brightness-apply
  }
''
