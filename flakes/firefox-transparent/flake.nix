{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: let
    pkgname = "firefox-transparent";
    forAllSystems = with nixpkgs.lib; f: foldAttrs mergeAttrs { }
      (map (s: { ${s} = f s; }) systems.flakeExposed);
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      firefox-transparent = pkgs.firefox.overrideAttrs (_final: old: {
        name = pkgname;
	nativeBuildInputs = old.nativeBuildInputs ++ [
	  pkgs.ghidra
	];
	buildCommand = old.buildCommand + ''
	  ${pkgs.ghidra}/lib/ghidra/support/analyzeHeadless \
	    fft \
	    -noanalysis \
	    -import ${pkgs.firefox}/lib/firefox/libxul.so \
	    -scriptPath ${.}
	    -postScript ghidraPost.py
	'';
      });
      default = firefox-transparent;
    });
  };
}

