{ inputs, config, lib, pkgs, ... }@args:
{
  imports = [ ./hardware-configuration.nix ./cachix.nix inputs.home-manager.nixosModules.home-manager ];
  documentation.nixos.enable = false;

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        gfxmodeEfi = "1920x1080";
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_zen;
    initrd.kernelModules = [ "nvidia" ];
    extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
    blacklistedKernelModules = [ "nouveau" ];
  };
  
  qt.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true; # todo: allowUnfreePredicate
  hardware = {
    opengl.enable = true; # hyprland
    nvidia = {
      open = true;
      modesetting.enable = true;
      powerManagement.enable = true;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
  security.rtkit.enable = true;
  services = {
    earlyoom.enable = true;
    xserver.videoDrivers = [ "nvidia" ];
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
    };
    openssh.enable = true;
    openvscode-server = {
      enable = true;
      user = "me";
    };
  };
  virtualisation.docker.enable = true;
  programs = {
    fish.enable = true;
    steam.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      configure = {
        customRC = ''
          :set guicursor=a:ver25
          :set number relativenumber
        '';
      };
    };
    git.enable = true;
    htop.enable = true;
    firefox = import ./programs/firefox.nix args;
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      fuse # appimages
      libinput # wlkey
      udev # wlkey
      glib # gobject for electron
      expat # playwright
      cairo # playwright
      alsaLib # asound for playwright and soloud
      xorg.libxcb # playwright
      xorg.libX11 # playwright
      xorg.libXcomposite # playwright
      xorg.libXdamage # playwright
      xorg.libXext # playwright
      xorg.libXfixes # playwright
      xorg.libXrandr # playwright
      nspr # playwright
      dbus # playwright
      atk # playwright
      cups # playwright
      libdrm # playwright
      pango # playwright
      libxkbcommon # playwright
      mesa # gbm for playwright
      nss # playwright
      gtk3
      vulkan-loader # unity
      libGL # unity
    ];
  };
  networking = {
    hostName = "pc";
    networkmanager.enable = true;
    firewall.enable = false;
  };
  time.timeZone = "Australia/Brisbane";
  users.users = {
    me = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" ];
      shell = pkgs.fish;
    };
    root = {
      initialHashedPassword = "";
      shell = pkgs.fish;
    };
  };
  home-manager.users.me = args2: let
    combined = args // args2;
  in
    { home.stateVersion = "23.11"; } // # initial version. NEVER EVER CHANGE!
    (import ./home-manager/hyprland.nix combined) //
    {
      xdg.portal = {
        enable = true;
	config = {
	  common.default = [ "hyprland" "gtk" ];
	};
	extraPortals = [
	  inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
	  pkgs.xdg-desktop-portal-gtk
	];
      };
    } //
    { services.wlsunset = { enable = true; latitude = "-27.5"; longitude = "153"; }; };
  environment.systemPackages = with pkgs; [
    cachix
    file
    pcmanfm
    home-manager
    pavucontrol
    alacritty
    #foot
    google-chrome 
    curl
    cava
    librsync # rdiff for binary patching
    wlsunset
    gallery-dl
    ntp # ntpdate
    qt6.qtsvg # alacritty icon
    #gammaray # qt debugging
    qt6.qtwayland # gammaray, qti
    qt6.qtmultimedia
    kdePackages.qtshadertools # qsb
    kdePackages.qt6ct # xdg-desktop-portal for file dialog
    sqlite # debugging itch butler
    xdg-utils # open, xdg-open
    ffmpeg-full
    rlwrap
    nixpkgs-fmt
    p7zip
    direnv
    wf-recorder
    clang-tools
    obs-studio
    mandoc # for aws help

    # rice
    pipes
    lolcat

    # vs code
    nixd

    # image manipulation
    krita
    graphicsmagick
    waifu2x-converter-cpp
    inkscape

    # screenshot
    grim
    (satty.overrideAttrs { patches = [ ./programs/satty/fullscreen.patch ]; })
    wl-clipboard

    nodejs_21
    electron
    bun
    wasm-pack
    python3 # node-gyp
    gnumake # node-gyp

    # debug
    gdbHostCpuOnly
    lsof

    # fun
    luajit
    ghidra

    # quickshell
    inputs.quickshell.packages.${pkgs.system}.nvidia
    playerctl # to read mpris data. will be obsoleted by proper dbus support

    # game
    #inputs.unicorn-scribbles.packages.${pkgs.system}.unicorn-scribbles
    #itch # broken on go 1.21+
    dxvk
    winetricks
    inputs.nix-gaming.packages.${pkgs.system}.wine-tkg
  ];
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    (nerdfonts.override {
      fonts = [ "FantasqueSansMono" ];
    })
  ];
  environment.sessionVariables = {
    # hyprland
    WLR_RENDERER = "vulkan";
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    # hyprland x nvidia
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1"; # electron
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = true;
    };
    # copySystemConfiguration = true; # backup this file to /run/current-system/. incompatible with flakes
    stateVersion = "23.11"; # initial version. NEVER EVER CHANGE!
  };
}

