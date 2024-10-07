{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: let
    pkgname = "wivrn-dashboard";
    pkgver = "0.19.1";
    forEachSystem = fn: nixpkgs.lib.genAttrs
      nixpkgs.lib.systems.flakeExposed
      (system: fn system nixpkgs.legacyPackages.${system});
  in {
    packages = forEachSystem (system: pkgs: let
      getName = let
        parse = drv: (builtins.parseDrvName drv).name;
      in x:
        if builtins.isString x
        then parse x
        else x.pname or (parse x.name);
      src = pkgs.fetchFromGitHub {
        name = pkgname;
        owner = "WiVRn";
        repo = "WiVRn";
        rev = "bcffadcd4e043d7bacd700b1331c2e98f96ca178";
        hash = "sha256-ZSVn0k1ACm5Zm4TuGZih2R/l4jXtAnt2bLJmGw/kPZk=";
      };
    in rec {
      wivrn-server = let
        pkgname = "wivrn-server";
	pkgver = "0.19";
      in pkgs.stdenv.mkDerivation {
        name = pkgname;
        version = pkgver;
        src = src;
	buildPhase = ''
          runHook preBuild
	  cmake -B build-server . -GNinja \
	    -DGIT_DESC=v${pkgver} \
	    -DWIVRN_BUILD_CLIENT=OFF \
	    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	    -DCMAKE_INSTALL_PREFIX="/usr" \
	    -DWIVRN_USE_VAAPI=ON \
	    -DWIVRN_USE_X264=ON \
	    -DWIVRN_USE_NVENC=ON \
	    -Wno-dev
	  cmake --build build-server
	  runHook postBuild
	'';
        installPhase = ''
          runHook preInstall
	  DESTDIR="$out" cmake --install build-server
          runHook postInstall
        '';
	# see https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=wivrn-server
	nativeBuildInputs = with pkgs; [
	  cmake
	  pkg-config
	  eigen
	  nlohmann_json
	  cli11
	  boost184
	];
	buildInputs = with pkgs; [
	  avahi
	  ffmpeg
	  pipewire
	  pulseaudio
	  xorg.libX11
	  xorg.libxcb
	  systemdLibs
	  vulkan-headers
	  vulkan-loader
	  x264
	  monado
	];
        meta = {
          homepage = "https://github.com/WiVRn/WiVRn";
	  description = "A wireless Monado-based OpenXR runtime for standalone headsets";
          license = nixpkgs.lib.licenses.gpl3;
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      wivrn-dashboard = pkgs.stdenv.mkDerivation {
        name = pkgname;
        version = pkgver;
        src = src;
	buildPhase = ''
          runHook preBuild
	  cmake -B build-dashboard . -GNinja \
	    -DGIT_DESC=v${pkgver} \
	    -DWIVRN_BUILD_CLIENT=OFF \
	    -DWIVRN_BUILD_SERVER=OFF \
	    -DWIVRN_BUILD_DASHBOARD=ON \
	    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	    -DCMAKE_INSTALL_PREFIX="/usr" \
	    -Wno-dev
	  cmake --build build-dashboard
	  runHook postBuild
	'';
        installPhase = ''
          runHook preInstall
	  DESTDIR="$out" cmake --install build-dashboard
          runHook postInstall
        '';
	# see https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=wivrn-dashboard
	nativeBuildInputs = with pkgs; [
	  cmake
	];
	buildInputs = with pkgs; [
	  qt6.qtbase
	  hicolor-icon-theme
	  wivrn-server
	];
        meta = {
          homepage = "https://github.com/WiVRn/WiVRn";
          description = "An OpenXR streaming application to a standalone headset";
          license = nixpkgs.lib.licenses.gpl3;
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      default = wivrn-dashboard;
    });
  };
}
