{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: let
    pkgname = "miku-cursor";
    forAllSystems = with nixpkgs.lib; f: foldAttrs mergeAttrs { }
      (map (s: { ${s} = f s; }) systems.flakeExposed);
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in rec {
      miku-cursor = pkgs.stdenv.mkDerivation {
        name = pkgname;
        version = "1.0.0";
        src = pkgs.fetchFromGitHub {
	  name = pkgname;
          owner = "OmeletWithoutEgg";
	  repo = "miku-cursor-theme";
	  rev = "341af5cafd5ed5bd00c9937fc4f55f4459091047";
	  hash = "sha256-RgpBdQdOTsXybDX7NE0wm6SyRp9BsUduxJrVoMFVeC0=";
	};
        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/icons/miku-cursor/
          cp -r . $out/share/icons/miku-cursor/
          runHook postInstall
        '';
        meta = {
          homepage = "https://www.opendesktop.org/p/2124099";
          description = "Hatsune Miku GTK cursor theme";
          #license = nixpkgs.lib.licenses.unfree;
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      default = miku-cursor;
    });
  };
}
