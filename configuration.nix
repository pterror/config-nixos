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
	  ".config/itch"
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
	files = [
	  "passwords.kdbx"
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
  };
  
  qt.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" "repl-flake" ];
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "google-chrome"
    "steam"
    "steam-original"
    "steam-run"
  ];
  hardware = {
    graphics.enable = true; # hyprland
    nvidia = {
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
    direnv.enable = true;
    firefox = import ./modules/firefox.nix args;
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
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      #libinput udev # wlkey
      glib # gobject for electron
      expat cairo # playwright
      alsaLib # asound for playwright (and soloud)
      xorg.libxcb # playwright
      xorg.libX11 # playwright
      xorg.libXcomposite # playwright
      xorg.libXdamage # playwright
      xorg.libXext # playwright
      xorg.libXfixes # playwright
      xorg.libXrandr # playwright
      nspr dbus atk cups libdrm pango # playwright
      libxkbcommon # playwright
      mesa # gbm for playwright
      nss # playwright
      gtk3
      vulkan-loader libGL # unity
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
    (import ./home-manager/kitty.nix combined)
    { services.wlsunset = { enable = true; latitude = "-27.5"; longitude = "153"; }; }
  ];
  environment.systemPackages = with pkgs; [
    home-manager
    cachix
    file
    pcmanfm
    pavucontrol
    google-chrome 
    curl
    cava
    wlsunset
    gallery-dl
    qt6.qtmultimedia
    qt6.qtwayland # idk if this fixes QT_QPA_PLATFORM=wayland
    kdePackages.qt6ct # xdg-desktop-portal for file dialog
    xdg-utils # open, xdg-open
    ffmpeg-full
    rlwrap
    p7zip
    wf-recorder
    clang-tools
    nixpkgs-fmt
    # vs code
    nixd
    # image manipulation
    krita
    graphicsmagick
    # debug
    gdbHostCpuOnly
    # quickshell
    inputs.quickshell.packages.${pkgs.system}.default
    # game
    dxvk
    winetricks
    inputs.nix-gaming.packages.${pkgs.system}.wine-tkg
    samba # ntlm_auth for wine
    prismlauncher
    r2modman
    cinny-desktop
    keepassxc
    # vr
    (pkgs.callPackage ./packages/sidequest.nix {}) alvr android-tools
  ] ++ /* qti */ inputs.qti.packages.${pkgs.system}.qti-all;
  services.udev.extraRules = ''
    SUBSYSTEM="usb", ATTR{idVendor}=="2833", ATTR{idProduct}=="0186", MODE="0660" group="plugdev", symlink+="ocuquest%n"
  '';
  fonts.packages = with pkgs; [
    inputs.unicorn-scribbles-font.packages.${pkgs.system}.default
    twemoji-color-font
    noto-fonts
    noto-fonts-cjk
    (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
  ];
  environment = {
    pathsToLink = [ "/share/qti" ];
    sessionVariables = {
      # hyprland
      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";
      QT_QPA_PLATFORM = "wayland";
      QT_QPA_PLATFORMTHEME = "qt6ct";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      # hyprland x nvidia
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  };
  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = true;
    };
    stateVersion = "23.11"; # initial version. NEVER EVER CHANGE!
  };
}

