# Runs chub-activity's probe inside the same `chub-vpn` network namespace
# built by chub-mirrorer (modules/chub-mirrorer.nix). This module does not
# set up or tear down the netns itself — it only depends on
# chub-vpn-netns.service and runs inside whatever namespace that service
# maintains. Add `./modules/chub-activity.nix` to imports.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.chub-activity;

  runScript = pkgs.writeShellApplication {
    name = "chub-activity-run";
    runtimeInputs = [
      pkgs.iproute2
      pkgs.util-linux
      pkgs.bun
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail
      exec ip netns exec "${cfg.netns}" \
        runuser -u "${cfg.user}" -- \
        env HOME="/home/${cfg.user}" PATH="${
          lib.makeBinPath [
            pkgs.bun
            pkgs.coreutils
            pkgs.bash
          ]
        }:/run/current-system/sw/bin" \
        bun run probe
    '';
  };
in
{
  options.services.chub-activity = {
    enable = lib.mkEnableOption "chub-activity netns-isolated probe runner";

    netns = lib.mkOption {
      type = lib.types.str;
      default = "chub-vpn";
      description = ''
        Name of the network namespace to run inside. Expected to already be
        set up by chub-mirrorer's chub-vpn-netns.service; this module does
        not create it.
      '';
    };

    workingDirectory = lib.mkOption {
      type = lib.types.path;
      default = "/home/me/git/pterror/chub-activity";
      description = ''
        Working directory for the probe process. Bun auto-loads a `.env`
        file from this directory, which is how CHUB_API_KEY reaches the
        process — no EnvironmentFile wiring is needed here.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "me";
      description = "User to drop privileges to when running bun.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group for the chub-activity process.";
    };

    schedule = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "hourly";
      description = ''
        If non-null, a systemd OnCalendar expression that triggers
        chub-activity.service on a timer (e.g. "hourly", "*:0/30",
        "daily"). Null disables the timer; start manually instead.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.chub-activity = {
      description = "Run chub-activity probe via WireGuard netns";
      after = [ "chub-vpn-netns.service" ];
      requires = [ "chub-vpn-netns.service" ];
      serviceConfig = {
        Type = "oneshot";
        # The outer process needs root to call `ip netns exec`; runuser
        # inside drops to the unprivileged user before invoking bun.
        User = "root";
        WorkingDirectory = cfg.workingDirectory;
        ExecStart = "${runScript}/bin/chub-activity-run";
      };
    };

    systemd.timers.chub-activity = lib.mkIf (cfg.schedule != null) {
      description = "Periodic chub-activity probe run";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
