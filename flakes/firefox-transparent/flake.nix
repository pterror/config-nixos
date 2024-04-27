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
	  cp -L lib/firefox/libxul.so lib/firefox/libxul.so.new
	  rm lib/firefox/libxul.so
	  mv lib/firefox/libxul.so.new lib/firefox/libxul.so
	  ls -al lib/firefox/
	  chmod +w lib/firefox/libxul.so
	  radare2 -c '
	    s sym.mozilla::PreferenceSheet::Prefs::LoadColors_bool_;
            af load_colors;
            s `pdi~NS_ComposeColors[0]`;
            s-4;
            wx ffffff00;
            s sym.nsWindow::Create_nsIWidget__void__mozilla::gfx::IntRectTyped_mozilla::LayoutDevicePixel__const__mozilla::widget::InitData_;
            af nswindow_create;
	    s `pdf~&and,ff[2]:2`;
	    s+21;
	    wx 48e9;
	    s $j;
	    s+9;
	    wx 670f18440000;
	  ' -w lib/firefox/libxul.so
	  chmod -w lib/firefox/libxul.so
	'';
      });
      default = firefox-transparent;
    });
  };
}

