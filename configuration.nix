{ inputs, config, lib, pkgs, ... }@args:
{
  imports = [ ./hardware-configuration.nix ./cachix.nix inputs.home-manager.nixosModules.home-manager ];
  documentation.nixos.enable = false;

  environment.persistence = {
    "/persistent" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
      ];
      files = [
      ];
      users.me = {
        directories = [
          { directory = ".gnupg"; mode = "0700"; }
          { directory = ".ssh"; mode = "0700"; }
          { directory = ".local/share/keyrings"; mode = "0700"; }
	  ".config/qt6ct" # TODO: move to declarative config
	  ".config/quickshell"
	  ".config/wallpapers"
	  { directory = ".config/omf"; mode = "0700"; } # TODO: move to declarative config
	  { directory = ".config/pipewire"; mode = "0700"; }
	  ".config/google-chrome"
	  ".config/fish"
	  ".config/tits"
	  ".config/gallery-dl"
	  ".mozilla/firefox"
	  ".openvscode-server"
	  ".aws"
	  ".wine"
	  ".local/share/pnpm"
	  ".local/share/fish"
	  ".local/share/omf"
	  ".local/share/Steam"
	  ".cargo" # for .cargo/bin/

	  "git"
	  "game"
	];
      };
    };
  };

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
    firefox = import ./modules/firefox.nix args;
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
      hashedPassword = "$y$j9T$cidkoWm0GGdY640fxDlg1.$MtxmsHZ0XIO7PvPGss/K0WPBE7NwJVhvH38gbg/gCpA";
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
  in lib.mkMerge [
    { home.stateVersion = "23.11"; } # initial version. NEVER EVER CHANGE!
    {
      home.pointerCursor = {
        gtk.enable = true;
	name = "miku-cursor";
	package = inputs.miku-cursor.packages.${pkgs.system}.default;
	size = 24;
      };
    }
    (import ./home-manager/hyprland.nix combined)
    {
      gtk = {
        theme.name = "Adwaita-dark";
        font = {
	  name = "Unicorn Scribbles";
	  package = inputs.unicorn-scribbles-font.packages.${pkgs.system}.default;
	  size = 10;
	};
      };
    }
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
    }
    (import ./home-manager/foot.nix combined)
    { services.wlsunset = { enable = true; latitude = "-27.5"; longitude = "153"; }; }
  ];
  environment.systemPackages = with pkgs; [
    cachix
    file
    pcmanfm
    home-manager
    pavucontrol
    google-chrome 
    curl
    cava
    wlsunset
    gallery-dl
    ntp # ntpdate
    qt6.qtsvg # svg app icons (if any)
    qt6.qtmultimedia
    kdePackages.qt6ct # xdg-desktop-portal for file dialog
    xdg-utils # open, xdg-open
    ffmpeg-full
    rlwrap
    nixpkgs-fmt
    p7zip
    direnv
    wf-recorder
    clang-tools

    # rice
    pipes
    lolcat

    # vs code
    nixd

    # image manipulation
    krita
    graphicsmagick
    inkscape

    # debug
    gdbHostCpuOnly

    # quickshell
    inputs.quickshell.packages.${pkgs.system}.nvidia
    playerctl # to read mpris data. will be obsoleted by proper dbus support

    # game
    #itch # broken on go 1.21+
    dxvk
    winetricks
    inputs.nix-gaming.packages.${pkgs.system}.wine-tkg
  ] ++ inputs.qti.packages.${pkgs.system}.all;
  fonts.packages = with pkgs; [
    inputs.unicorn-scribbles-font.packages.${pkgs.system}.default
    noto-fonts
    noto-fonts-cjk
    (nerdfonts.override {
      fonts = [ "Monofur" ];
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
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = true;
    };
    stateVersion = "23.11"; # initial version. NEVER EVER CHANGE!
  };
}

