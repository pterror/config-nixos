# Simple helper to symlink config files - no magic, just less repetition
{ pkgs, lib }:

{
  # mkUserConfig: creates a config file and returns activation script
  # Example: mkUserConfig { path = ".config/hypr/hyprland.conf"; config = ./config/hyprland.nix; args = ...; }
  mkUserConfig = { username, homeDirectory, path, config, args ? {} }:
    let
      configFile = pkgs.writeText (lib.last (lib.splitString "/" path)) (pkgs.callPackage config args);
    in
    ''
      echo "Setting up ${path}"
      ${pkgs.coreutils}/bin/mkdir -p "${homeDirectory}/$(dirname ${path})"
      ${pkgs.coreutils}/bin/ln -sf "${configFile}" "${homeDirectory}/${path}"
    '';
}
