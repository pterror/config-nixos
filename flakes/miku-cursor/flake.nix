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
          owner = "supermariofps";
	  repo = "hatsune-miku-windows-linux-cursors";
	  rev = "24bbed734c17bc19516b939ee10203b229513d2a";
	  hash = "sha256-m5CDmAATxtQgjV5Ij+5bF3QQ8Na3pXPNmQUtwHwwWFc=";
	};
        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/icons/
          cp -r miku-cursor-linux $out/share/icons/miku-cursor
          runHook postInstall
        '';
        meta = {
          homepage = "https://www.opendesktop.org/p/2124099";
          description = "Hatsune Miku X11 cursor theme";
          #license = nixpkgs.lib.licenses.unfree;
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      default = miku-cursor;
    });
  };
}
