{ config, lib, pkgs, ...}:
let
  inherit (lib) mkIf mkPackageOption mkEnableOption types;

  cfg = config.services.quickshell;
in {
  options.services.quickshell = {
    enable = mkEnableOption "quickshell";
    package = mkPackageOption pkgs "quickshell" {
      default = null;
    };
    baseConfigPackage = mkPackageOption pkgs "quickshell-config" {
      default = null;
    };
    config = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        JSON configuration.
      '';
    };
    systemdTarget = mkOption {
      type = types.str;
      default = "graphical-session.target";
      description = ''
        Systemd target to bind to.
      '';
    };
    userLib = mkOption {
      type = types.str;
      default = '''';
      description = ''
        Extra JavaScript functions and variables used by the configuration.
	Values should be `export`ed. Use in configuration as `["user-lib", "name"]`.
      '';
    };
  };
  config = mkIf cfg.enable {
    systemd.user.services.quickshell = {
      Unit = {
        Description =
	  "";
	PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
	Restart = "always";
      };

      Install.WantedBy = [ cfg.systemdTarget ];
    };

    # TODO: import base config
    xdg.configFile."quickshell/config/theme/config.json" = {
      text = toJSON cfg.config;
    };
  };
};
