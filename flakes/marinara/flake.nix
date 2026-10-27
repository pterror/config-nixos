{
  description = "Marinara Engine (AI chat & roleplay frontend), packaged from upstream";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # Bumping this needs the pnpmDeps hash in package.nix bumped too.
    marinara-src = {
      url = "github:Pasta-Devs/Marinara-Engine";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      marinara-src,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        # Override llama-cpp with a GPU build (and wrapperEnv) where it is used.
        marinara-engine = pkgs.callPackage ./package.nix { src = marinara-src; };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.marinara-engine;
      });
    };
}
