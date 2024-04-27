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
    in rec {
      firefox-transparent = pkgs.firefox.overrideAttrs (_final: old: {
        name = pkgname;
	nativeBuildInputs = old.nativeBuildInputs ++ [
	  pkgs.radare2
	];
	buildCommand = old.buildCommand + ''
	  ls
	  radare2 -w lib/firefox/libxul.so -i '\
	    s sym.mozilla::PreferenceSheet::Prefs::LoadColors_bool_; \
            af load_colors; \
            s `pdi~NS_ComposeColors[0]`; \
            s-5; \
            wx ffffff00 @ 1; \
            s sym.nsWindow::Create_nsIWidget__void__mozilla::gfx::IntRectTyped_mozilla::LayoutDevicePixel__const__mozilla::widget::InitData_; \
            af nswindow_create; \
	    s `pdf~&and,ff[2]:2`; \
	    s+21; \
	    w 48e9; \
	    s $j; \
	    s+9; \
	    w 670f18440000; \
	  '
	  ls
	'';
      });
      default = firefox-transparent;
    });
  };
}

