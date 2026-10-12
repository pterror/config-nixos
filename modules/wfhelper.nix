# Patched natively rather than via appimageTools.wrapType2: the bwrap sandbox
# that wrapType2 (and steam-run/appimage-run) uses puts the app in its own user
# namespace, a sibling of Steam/pressure-vessel's, so the kernel refuses to let
# it ptrace/read Warframe's memory no matter what ptrace_scope is set to. Run
# from the init namespace, it is an ancestor of Steam's and the read is allowed.
{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  gtk-layer-shell,
  libdrm,
  libgbm,
  libGL,
  libnotify,
  libpulseaudio,
  libsecret,
  libuuid,
  libxkbcommon,
  nspr,
  nss,
  pango,
  systemd,
  wayland,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxscrnsaver,
  libxtst,
}:
let
  pname = "wfhelper";
  version = "2.1.1";

  src = fetchurl {
    url = "https://github.com/WFHelper/WFHelper/releases/download/v${version}/WFHelper-${version}.AppImage";
    hash = "sha256-04lf525fLcWC9yI6Bw4PZn0MUZNUfKrypvVqfoCvRdM=";
  };

  contents = appimageTools.extract { inherit pname version src; };

  libvipsCpp = "resources/app.asar.unpacked/node_modules/@img/sharp-libvips-linux-x64/lib/libvips-cpp.so.8.18.6";

  runtimeLibs = [
    stdenv.cc.cc.lib
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    gtk-layer-shell
    libdrm
    libgbm
    libGL
    libnotify
    libpulseaudio
    libsecret
    libuuid
    libxkbcommon
    nspr
    nss
    pango
    systemd
    wayland
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxscrnsaver
    libxtst
  ];
in
stdenv.mkDerivation {
  inherit pname version;
  src = contents;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = runtimeLibs;

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin $out/share/applications
    cp -r . $out/opt/wfhelper
    chmod -R u+w $out/opt/wfhelper
    rm -rf $out/opt/wfhelper/{AppRun,usr,chrome-sandbox,.DirIcon,wfhelper.png,wfhelper.desktop}

    # koffi ships prebuilts for every platform; keep only ours.
    find $out/opt/wfhelper/resources/app.asar.unpacked/node_modules/koffi/build/koffi \
      -mindepth 1 -maxdepth 1 ! -name linux_x64 -exec rm -rf {} +

    # Opens the ptrace window from modules/wf-ptrace.nix (polkit prompt). If
    # it is declined, WFHelper still runs, just without memory reading.
    makeWrapper $out/opt/wfhelper/wfhelper $out/bin/wfhelper \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
      --run '${systemd}/bin/systemctl is-active --quiet wf-ptrace.service || ${systemd}/bin/systemctl start wf-ptrace.service || true'

    install -Dm444 wfhelper.desktop $out/share/applications/wfhelper.desktop
    sed -i 's|^Exec=[^ ]*|Exec=wfhelper|' $out/share/applications/wfhelper.desktop
    cp -r usr/share/icons $out/share/

    runHook postInstall
  '';

  # patchelf corrupts sharp's bundled libvips-cpp (segfault in its ELF init on
  # dlopen). It only needs glibc + libstdc++, so keep it out of autoPatchelf
  # and let the wrapper's LD_LIBRARY_PATH supply libstdc++.
  # The hook's automatic run comes after postFixup, so drive it by hand.
  dontAutoPatchelf = true;
  autoPatchelfIgnoreMissingDeps = [ (baseNameOf libvipsCpp) ];
  postFixup = ''
    mv $out/opt/wfhelper/${libvipsCpp} libvips-cpp.so.unpatched
    autoPatchelf $out
    mv libvips-cpp.so.unpatched $out/opt/wfhelper/${libvipsCpp}
    # autoPatchelf replaced sharp's $ORIGIN rpath; point it back at libvips.
    patchelf --add-rpath '$ORIGIN/../../sharp-libvips-linux-x64/lib' \
      $out/opt/wfhelper/resources/app.asar.unpacked/node_modules/@img/sharp-linux-x64/lib/sharp-linux-x64-*.node
  '';
}
