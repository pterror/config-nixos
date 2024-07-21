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
      getName = let
        parse = drv: (builtins.parseDrvName drv).name;
      in x:
        if builtins.isString x
        then parse x
        else x.pname or (parse x.name);
      pkgs = import nixpkgs {
        system = system;
	config.allowUnfreePredicate = pkg: getName pkg == "unicorn-scribbles-font";
      };
    in rec {
      unicorn-scribbles-font = pkgs.stdenv.mkDerivation {
        name = pkgname;
        version = "1.0.0";
	nativeBuildInputs = with pkgs; [ unzip ];
	# resized to 125% so it cannot be obtained directly from the source
	src = ./unicorn-scribbles.otf;
	dontUnpack = true;
        /*src = pkgs.fetchzip {
	  name = pkgname;
	  url = "https://dl.dafont.com/dl/?f=unicorn_scribbles";
	  extension = "zip";
	  hash = "sha256-tr57tk/yzu0mDYGYoy+CpenRQG4dlbV6SaYP/8H2GBg=";
	};*/
        url = "https://www.dafont.com/unicorn-scribbles.font";
        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/fonts
          cp $src $out/share/fonts/
          runHook postInstall
        '';
        meta = {
          homepage = "https://www.dafont.com/unicorn-scribbles.font";
          description = "A typeface specially designed for user interfaces";
          license = nixpkgs.lib.licenses.unfree;
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      default = unicorn-scribbles-font;
    });
  };
}

