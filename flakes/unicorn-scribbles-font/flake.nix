{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: let
    pkgname = "unicorn-scribbles-font";
    forAllSystems = with nixpkgs.lib; f: foldAttrs mergeAttrs { }
      (map (s: { ${s} = f s; }) systems.flakeExposed);
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in rec {
      unicorn-scribbles-font = pkgs.stdenv.mkDerivation {
        name = pkgname;
        version = "1.0.0";
	nativeBuildInputs = with pkgs; [ unzip ];
        src = pkgs.fetchzip {
	  name = pkgname;
	  url = "https://dl.dafont.com/dl/?f=unicorn_scribbles";
	  extension = "zip";
	  hash = "sha256-tr57tk/yzu0mDYGYoy+CpenRQG4dlbV6SaYP/8H2GBg=";
	};
        url = "https://www.dafont.com/unicorn-scribbles.font";
        sha256 = "a485afeaad61c9d8488a5363a34404336ae8b758fdf383c9556fcd64a6736202";
	unpackCmd = "";
        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/fonts
          cp 'Unicorn Scribbles.otf' $out/share/fonts/unicorn-scribbles.otf
          runHook postInstall
        '';
        meta = {
          homepage = "https://www.dafont.com/unicorn-scribbles.font";
          description = "A typeface specially designed for user interfaces";
          #license = nixpkgs.lib.licenses.unfree;
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      default = unicorn-scribbles-font;
    });
  };
}

