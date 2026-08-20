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
    on-resume = headless-resume
  }
''
