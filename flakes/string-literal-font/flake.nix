{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: let
    pkgname = "string-literal-font";
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
	config.allowUnfreePredicate = pkg: getName pkg == "string-literal-font";
      };
    in rec {
      string-literal-font = pkgs.stdenv.mkDerivation {
        name = pkgname;
        version = "1.0.0";
	nativeBuildInputs = with pkgs; [ unzip ];
        src = pkgs.fetchzip {
	  name = pkgname;
	  url = "https://dl.dafont.com/dl/?f=string_variable_literal";
	  extension = "zip";
	  hash = "sha256-bF134EA0HAVNqEZG5sgLEJa5RTLQMJUDYSMw2+DwlaQ=";
	  stripRoot = false;
	};
        url = "https://www.dafont.com/string-variable-literal.font";
        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/fonts
          cp $src/*.ttf $out/share/fonts/
          runHook postInstall
        '';
        meta = {
          homepage = "https://www.dafont.com/string-variable-literal.font";
          description = "String Literal font";
          license = nixpkgs.lib.licenses.unfree;
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      default = string-literal-font;
    });
  };
}

