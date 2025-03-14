{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: let
    pkgname = "pointfree-font";
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
      pkgs = import nixpkgs { system = system; };
    in rec {
      pointfree-font = pkgs.stdenv.mkDerivation {
        name = pkgname;
        version = "1.0.0";
	nativeBuildInputs = with pkgs; [ unzip ];
        src = pkgs.fetchzip {
	  name = pkgname;
	  url = "https://dl.dafont.com/dl/?f=pointfree";
	  extension = "zip";
	  hash = "sha256-lqd/UXdYqwfcbdG5NIHlFuEpYIoAPL7jzjEjHtx6SeY=";
	  stripRoot = false;
	};
        url = "https://www.dafont.com/pointfree.font";
        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/fonts
          cp $src/*.ttf $out/share/fonts/
          runHook postInstall
        '';
        meta = {
          homepage = "https://www.dafont.com/pointfree.font";
          description = "Pointfree font";
          license = nixpkgs.lib.licenses.unlicense;
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      default = pointfree-font;
    });
  };
}

