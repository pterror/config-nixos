# Runs chub-mirrorer inside a dedicated network namespace (`chub-vpn`)
# whose only route is a WireGuard interface built from a wg-quick-style conf.
# The root netns is untouched. Add `./modules/chub-mirrorer.nix` to imports.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.chub-mirrorer;

  setupScript = pkgs.writeShellApplication {
    name = "chub-vpn-setup";
    runtimeInputs = [
      pkgs.iproute2
      pkgs.wireguard-tools
      pkgs.gnugrep
      pkgs.gnused
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail

      NETNS="${cfg.netns}"
      WG_IF="wg-chub"
      CONF="${cfg.wireguardConfig}"

      if [ ! -r "$CONF" ]; then
        echo "chub-mirrorer: wireguard config not readable at $CONF" >&2
        exit 1
      fi

      # Parse [Interface] Address and DNS from the conf. The wg-quick
      # PostUp/PreUp/Table directives are intentionally ignored — we only
      # consume the cryptographic peer config via `wg-quick strip`.
      ADDRESS="$(sed -n 's/^[[:space:]]*Address[[:space:]]*=[[:space:]]*//p' "$CONF" | head -n1 | tr -d '[:space:]')"
      DNS="$(sed -n 's/^[[:space:]]*DNS[[:space:]]*=[[:space:]]*//p' "$CONF" | head -n1 | tr -d '[:space:]')"

      if [ -z "$ADDRESS" ]; then
        echo "chub-mirrorer: no Address= in $CONF" >&2
        exit 1
      fi

      # Idempotent teardown of any prior state.
      if ip netns list | grep -qw "$NETNS"; then
        ip netns del "$NETNS"
      fi
      if ip link show "$WG_IF" >/dev/null 2>&1; then
        ip link del "$WG_IF"
      fi

      ip netns add "$NETNS"
      ip link add "$WG_IF" type wireguard
      ip link set "$WG_IF" netns "$NETNS"

      # `wg setconf` reads from a file descriptor; the stripped conf only
      # contains the [Interface] PrivateKey/ListenPort and [Peer] blocks.
      ip netns exec "$NETNS" wg setconf "$WG_IF" <(wg-quick strip "$CONF")

      # Address may be comma-separated (IPv4 + IPv6); add each.
      echo "$ADDRESS" | tr ',' '\n' | while read -r addr; do
        addr_trimmed="$(echo "$addr" | tr -d '[:space:]')"
        [ -n "$addr_trimmed" ] && ip -n "$NETNS" address add "$addr_trimmed" dev "$WG_IF"
      done
      ip -n "$NETNS" link set "$WG_IF" up
      ip -n "$NETNS" link set lo up
      ip -n "$NETNS" route add default dev "$WG_IF"
      ip -n "$NETNS" -6 route add default dev "$WG_IF" 2>/dev/null || true

      install -d -m 0755 "/etc/netns/$NETNS"
      if [ -n "$DNS" ]; then
        : > "/etc/netns/$NETNS/resolv.conf"
        # DNS may be comma-separated.
        echo "$DNS" | tr ',' '\n' | while read -r ns; do
          ns_trimmed="$(echo "$ns" | tr -d '[:space:]')"
          [ -n "$ns_trimmed" ] && echo "nameserver $ns_trimmed" >> "/etc/netns/$NETNS/resolv.conf"
        done
      else
        echo "nameserver 1.1.1.1" > "/etc/netns/$NETNS/resolv.conf"
      fi
    '';
  };

  teardownScript = pkgs.writeShellApplication {
    name = "chub-vpn-teardown";
    runtimeInputs = [ pkgs.iproute2 ];
    text = ''
      set -euo pipefail
      NETNS="${cfg.netns}"
      if ip netns list | grep -qw "$NETNS"; then
        ip netns del "$NETNS"
      fi
      rm -f "/etc/netns/$NETNS/resolv.conf" || true
      rmdir "/etc/netns/$NETNS" 2>/dev/null || true
    '';
  };

  runScript = pkgs.writeShellApplication {
    name = "chub-mirrorer-run";
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
        env HOME="/home/${cfg.user}" NAMESPACE=all PATH="${
          lib.makeBinPath [
            pkgs.bun
            pkgs.coreutils
            pkgs.bash
          ]
        }:/run/current-system/sw/bin" \
        bun run src/main.ts ${lib.escapeShellArgs cfg.extraArgs}
    '';
  };
in
{
  options.services.chub-mirrorer = {
    enable = lib.mkEnableOption "chub-mirrorer netns-isolated WireGuard runner";

    netns = lib.mkOption {
      type = lib.types.str;
      default = "chub-vpn";
      description = "Name of the network namespace to create.";
    };

    wireguardConfig = lib.mkOption {
      type = lib.types.path;
      default = "/home/me/.config/wireguard/proton.conf";
      description = "Path to a wg-quick-format WireGuard config.";
    };

    workingDirectory = lib.mkOption {
      type = lib.types.path;
      default = "/home/me/git/pterror/chub-mirrorer";
      description = "Working directory for the mirrorer process.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "me";
      description = "User to drop privileges to when running bun.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group for the mirrorer process.";
    };

    schedule = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "hourly";
      description = ''
        If non-null, a systemd OnCalendar expression that triggers
        chub-mirrorer.service on a timer (e.g. "hourly", "*:0/30",
        "daily"). Null disables the timer; start manually instead.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--incremental" ];
      description = "Extra arguments appended to `bun run src/main.ts`.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."chub-vpn-netns" = {
      description = "Set up chub-vpn WireGuard network namespace";
      wantedBy = [ ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${setupScript}/bin/chub-vpn-setup";
        ExecStop = "${teardownScript}/bin/chub-vpn-teardown";
      };
    };

    systemd.services.chub-mirrorer = {
      description = "Mirror chub.ai character cards via WireGuard netns";
      after = [ "chub-vpn-netns.service" ];
      requires = [ "chub-vpn-netns.service" ];
      serviceConfig = {
        Type = "oneshot";
        # The outer process needs root to call `ip netns exec`; runuser
        # inside drops to the unprivileged user before invoking bun.
        User = "root";
        WorkingDirectory = cfg.workingDirectory;
        ExecStart = "${runScript}/bin/chub-mirrorer-run";
      };
    };

    systemd.timers.chub-mirrorer = lib.mkIf (cfg.schedule != null) {
      description = "Periodic chub-mirrorer run";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
