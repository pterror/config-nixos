{ inputs, config, lib, pkgs, ... }@args:
{
  imports = [ ./hardware-configuration.nix ./cachix.nix inputs.home-manager.nixosModules.home-manager ];
  documentation.nixos.enable = false;

  nix.settings = {
    substituters = [
      "https://nix-community.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://stardustxr.cachix.org"
      "https://eigenvalue.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "stardustxr.cachix.org-1:mWSn8Ap2RLsIWT/8gsj+VfbJB6xoOkPaZpbjO+r9HBo="
      "eigenvalue.cachix.org-1:ykerQDDa55PGxU25CETy9wF6uVDpadGGXYrFNJA3TUs="
    ];
  };

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
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.overlays = [
    (final: prev: {
      breakpad = prev.breakpad.override { stdenv = final.gcc13Stdenv; };
    })
  ];
  #nixpkgs.config.cudaSupport = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "google-chrome"
    "steam"
    "steam-unwrapped"
    "steam-run"
    "reaper"
    # for wivrn
    "cuda-merged"
    "cuda_cuobjdump"
    "cuda_gdb"
    "cuda_nvcc"
    "cuda_nvdisasm"
    "cuda_nvprune"
    "cuda_cccl"
    "cuda_cudart"
    "cuda_cupti"
    "cuda_cuxxfilt"
    "cuda_nvml_dev"
    "cuda_nvrtc"
    "cuda_nvtx"
    "libnpp"
    "libcublas"
    "libcufft"
    "libcurand"
    "libcusparse"
    "libnvjitlink"
    "cudnn"
    "cuda_profiler_api"
    "cuda_sanitizer_api"
    "libcusolver"
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
  networking = {
    hostName = "pc";
    networkmanager.enable = true;
    firewall.enable = false;
  };
  services = {
    earlyoom.enable = true;
    tailscale.enable = true;
    transmission = {
      enable = true;
      user = "me";
      settings.download-dir = "/mnt/usb/game/";
    };
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
    sunshine.enable = true;
    openvscode-server = {
      enable = true;
      user = "me";
      host = "0.0.0.0";
    };
    udev.extraRules = ''
      SUBSYSTEM="usb", ATTR{idVendor}=="2833", ATTR{idProduct}=="0186", MODE="0660" group="plugdev", symlink+="ocuquest%n"
    '';
    #wivrn = {
    #  enable = true;
    #  autoStart = true;
    #};
  };
  virtualisation.docker.enable = true;
  programs = {
    fish.enable = true;
    steam.enable = true;
    direnv.enable = true;
    git.enable = true;
    adb.enable = true;
    firefox = import ./modules/firefox.nix args;
    neovim = {
      enable = true;
      defaultEditor = true;
      configure = {
        customRC = ''
                    :set guicursor=a:ver25
                    :set number relativenumber
          	  highlight Normal ctermbg=NONE guibg=NONE
          	  augroup user_colors
                      autocmd!
                      autocmd ColorScheme * highlight Normal ctermbg=NONE guibg=NONE
                    augroup END
        '';
      };
    };
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      #libinput udev # wlkey
      glib # gobject for electron
      expat
      cairo # playwright
      alsa-lib # asound for playwright (and soloud)
      xorg.libxcb # playwright
      xorg.libX11 # playwright
      xorg.libXcomposite # playwright
      xorg.libXdamage # playwright
      xorg.libXext # playwright
      xorg.libXfixes # playwright
      xorg.libXrandr # playwright
      nspr
      dbus
      atk
      cups
      libdrm
      pango # playwright
      libxkbcommon # playwright
      mesa # gbm for playwright
      nss # playwright
      gtk3
      vulkan-loader
      libGL # unity
    ];
  };
  time.timeZone = "Australia/Brisbane";
  users = {
    users = {
      me = {
        hashedPassword = "$y$j9T$cidkoWm0GGdY640fxDlg1.$MtxmsHZ0XIO7PvPGss/K0WPBE7NwJVhvH38gbg/gCpA";
        isNormalUser = true;
        extraGroups = [ "wheel" "docker" "adbusers" ];
        shell = pkgs.fish;
      };
      root = {
        initialHashedPassword = "";
        shell = pkgs.fish;
      };
    };
    extraGroups = {
      vboxusers.members = [ "me" ];
    };
  };
  home-manager.users.me = args2:
    let
      combined = args // args2;
    in
    lib.mkMerge [
      {
        home.stateVersion = "23.11"; # initial version. NEVER EVER CHANGE!
        home.pointerCursor = {
          gtk.enable = true;
          name = "miku-cursor";
          package = inputs.miku-cursor.packages.${pkgs.system}.default;
          size = 24;
        };
        gtk = {
          theme.name = "Adwaita-dark";
          font = {
            name = "Unicorn Scribbles";
            package = inputs.unicorn-scribbles-font.packages.${pkgs.system}.default;
            size = 10;
          };
        };
        services.wlsunset = { enable = true; latitude = "-27.5"; longitude = "153"; };
      }
      (import ./home-manager/hyprland.nix combined)
      (import ./home-manager/kitty.nix combined)
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
    # qt6.qtbase # eglfs_kms for wayland-compositor
    qt6.qtvirtualkeyboard # optional dependency for wayland-compositor
    vulkan-loader # libvulkan for wayland-compositor
    kdePackages.qt6ct # xdg-desktop-portal for file dialog
    xdg-utils # open, xdg-open
    ffmpeg-full
    rlwrap
    _7zz
    unrar-wrapper
    wf-recorder
    clang-tools
    nixpkgs-fmt
    reaper
    #jetbrains.idea-community
    vesktop
    btop
    bat
    luajit
    itch
    cargo-mommy
    /*((mommy.override {
      mommySettings =
        let
          cargo-mommy = import ./modules/cargo-mommy.nix;
          moods = cargo-mommy.withMoods [
            "mommy"
            "mommy"
            "mommy"
            "chill"
            "chill"
            "chill"
            "thirsty"
            "thirsty"
            "thirsty"
            "yikes"
          ];
        in
        {
          caregiver = "uwu/NixOWOS";
          sweetie = "cutie";
          suffix = "//~/~/ :3/ :3/ uwu/ owo";
          color = "182/183/218/219/225";
        } // moods;
    }).overrideAttrs (self: super: {
      postInstall = builtins.replaceStrings
        [ "--set-default MOMMY_OPT_CONFIG_FILE " ]
        [ "--add-flags -c --add-flags " ]
        super.postInstall;
      patches = [ ./modules/mommy_yikes.patch ];
    }))*/
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
    gamescope
    gamemode
    inputs.nix-gaming.packages.${pkgs.system}.wine-tkg
    samba # ntlm_auth for wine
    prismlauncher
    r2modman
    flatpak
    keepassxc
    # lumafly
    # vr
    (sidequest.overrideAttrs (super: {
      nativeBuildInputs = super.nativeBuildInputs ++ [ wrapGAppsHook ];
    }))
    alvr
    android-tools
    # inputs.hwfetch.packages.${pkgs.system}.default
    # inputs.verdi.packages.${pkgs.system}.default
    # inputs.asciinema.packages.${pkgs.system}.default
    inputs.stardust-telescope.packages.${pkgs.system}.telescope
    inputs.stardust-telescope.packages.${pkgs.system}.flatscreen
  ] ++ /* qti */ inputs.qti.packages.${pkgs.system}.qti-all;
  fonts.packages = with pkgs; [
    inputs.unicorn-scribbles-font.packages.${pkgs.system}.default
    twemoji-color-font
    noto-fonts
    noto-fonts-cjk-sans
    nerd-fonts.fantasque-sans-mono
  ];
  environment = {
    pathsToLink = [ "/share/qti" ];
    sessionVariables = {
      # hyprland
      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";
      QT_QPA_PLATFORMTHEME = "qt6ct";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QSG_USE_SIMPLE_ANIMATION_DRIVER = "0"; # fix quickshell lag
      # hyprland x nvidia
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      # can fix steam shader precaching pls?
      __GL_SHADER_DISK_CACHE_SIZE = "100000000000";
    };
  };
  xdg.portal = {
    enable = true;
    config = {
      common.default = [ "hyprland" "gtk" ];
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };
  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = true;
    };
    stateVersion = "23.11"; # initial version. NEVER EVER CHANGE!
  };
}

