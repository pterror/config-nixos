# Lowers kernel.yama.ptrace_scope only while WFHelper/Warframe are running, so
# WFHelper can read the game's memory without leaving it at 0 the rest of the
# time.
#
# The wfhelper launcher (modules/wfhelper.nix) starts this service through
# systemctl, so polkit asks for your password -- anything that could flip it
# without one could equally be flipped by malware running as you. The service
# sets ptrace_scope=0, holds while either process is running, then restores
# ptrace_scope=1. `wf-ptrace [on|off]` does the same by hand.
{ pkgs, ... }:
let
  sysctl = "${pkgs.procps}/bin/sysctl";
  pgrep = "${pkgs.procps}/bin/pgrep";

  session = pkgs.writeShellScript "wf-ptrace-session" ''
    running() { ${pgrep} -i warframe >/dev/null || ${pgrep} -x wfhelper >/dev/null; }
    ${sysctl} -w kernel.yama.ptrace_scope=0
    # Give either up to 15 minutes to show up, then hold until both exit.
    for _ in $(seq 180); do
      running && break
      sleep 5
    done
    while running; do
      sleep 5
    done
  '';

  wf-ptrace = pkgs.writeShellScriptBin "wf-ptrace" ''
    case "''${1:-on}" in
      on) exec systemctl start wf-ptrace.service ;;
      off) exec systemctl stop wf-ptrace.service ;;
      *) echo "usage: wf-ptrace [on|off]" >&2; exit 1 ;;
    esac
  '';
in
{
  boot.kernel.sysctl."kernel.yama.ptrace_scope" = 1;

  systemd.services.wf-ptrace = {
    description = "Allow ptrace while WFHelper/Warframe are running";
    serviceConfig = {
      Type = "simple";
      ExecStart = session;
      # Runs however the session ends: exit, timeout, stop, or failure.
      ExecStopPost = "${sysctl} -w kernel.yama.ptrace_scope=1";
    };
  };

  environment.systemPackages = [ wf-ptrace ];
}
