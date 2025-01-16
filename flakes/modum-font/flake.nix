{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: let
    pkgname = "modum-font";
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
	config.allowUnfreePredicate = pkg: getName pkg == "modum-font";
      };
    in rec {
      modum-font = pkgs.stdenv.mkDerivation {
        name = pkgname;
        version = "1.0.0";
	nativeBuildInputs = with pkgs; [ unzip ];
        src = pkgs.fetchzip {
	  name = pkgname;
	  url = "https://dl.dafont.com/dl/?f=modum";
	  extension = "zip";
	  hash = "sha256-/3B7EN4iCBaU9j2/YozI0cvmdhkZjsHzTTb0NcsP7Ns=";
	  stripRoot = false;
	};
        url = "https://www.dafont.com/modum.font";
        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/fonts
          cp $src/*.ttf $out/share/fonts/
          runHook postInstall
        '';
        meta = {
          homepage = "https://www.dafont.com/modum.font";
          description = "A geometric, modular, monoline, monospaced sans-serif font based on rounded shapes.";
          license = nixpkgs.lib.licenses.unfree;
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      default = modum-font;
    });
  };
}

