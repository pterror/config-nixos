{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    ./hardware-configuration.nix
    ./cachix.nix
    inputs.home-manager.nixosModules.home-manager
  ];
  documentation.nixos.enable = false;

  nix.settings = {
    substituters = [
      "https://cache.garnix.io"
      "https://nix-community.cachix.org"
      "https://ai.cachix.org"
      "https://cache.nixos.org"
      "https://numtide.cachix.org"
    ];
    trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
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
          {
            directory = ".gnupg";
            mode = "0700";
          }
          {
            directory = ".ssh";
            mode = "0700";
          }
          {
            directory = ".local/share/keyrings";
            mode = "0700";
          }
          ".config/qt6ct"
          ".config/quickshell"
          ".config/wallpapers"
          {
            directory = ".config/omf";
            mode = "0700";
          }
          {
            directory = ".config/pipewire";
            mode = "0700";
          }
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
          ".cargo"
          "git"
          "game"
          "Dendron"
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
        memtest86.enable = true;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_zen;
    extraModprobeConfig = ''
      options rtw89_core disable_ps_mode=Y
    '';
  };

  qt.enable = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "google-chrome"
      "steam"
      "steam-unwrapped"
      "steam-run"
      "claude-code"
    ];
  hardware = {
    rasdaemon.enable = true;
    graphics.enable = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
  security.rtkit.enable = true;
  networking = {
    hostName = "pc";
    networkmanager.enable = true;
    firewall = {
      enable = false;
      checkReversePath = false;
    };
  };
  services = {
    earlyoom.enable = true;
    tailscale.enable = true;
    fwupd.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    openssh.enable = true;
  };
  programs = {
    fish.enable = true;
    steam.enable = true;
    direnv.enable = true;
    git.enable = true;
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
  };
  time.timeZone = "Australia/Brisbane";
  users = {
    users = {
      me = {
        hashedPassword = "$y$j9T$cidkoWm0GGdY640fxDlg1.$MtxmsHZ0XIO7PvPGss/K0WPBE7NwJVhvH38gbg/gCpA";
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
      };
      root = {
        initialHashedPassword = "";
        shell = pkgs.fish;
      };
    };
  };
  home-manager.users.me =
    args2:
    let
      combined = args // args2;
    in
    lib.mkMerge [
      {
        home.stateVersion = "23.11"; # initial version. NEVER EVER CHANGE!
        home.pointerCursor = {
          gtk.enable = true;
          name = "miku-cursor";
          package = inputs.miku-cursor.packages.${system}.default;
          size = 24;
        };
        gtk = {
          theme.name = "Adwaita-dark";
          font = {
            name = "Unicorn Scribbles";
            package = inputs.unicorn-scribbles-font.packages.${system}.default;
            size = 10;
          };
        };
        services.wlsunset = {
          enable = true;
          latitude = "-27.5";
          longitude = "153";
        };
      }
    ];
  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = [ "multi-user.target" ];
  environment.systemPackages =
    with pkgs;
    [
      (hyprland.override { enableXWayland = true; })
      xwayland
      home-manager
      cachix
      file
      pcmanfm
      pavucontrol
      google-chrome
      curl
      qt6.qtwayland
      kdePackages.qt6ct
      xdg-utils
      htop
      bat
      lact
      (pkgs.callPackage ./modules/claude-code.nix {})
      github-cli
      amdgpu_top
      nixd
      inputs.quickshell.packages.${system}.default
      inputs.nix-gaming.packages.${system}.wine-tkg
      samba
      keepassxc
    ]
    ++ inputs.qti.packages.${system}.qti-all;
  fonts.packages = with pkgs; [
    inputs.unicorn-scribbles-font.packages.${system}.default
    inputs.pointfree-font.packages.${system}.default
    twemoji-color-font
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    nerd-fonts.fantasque-sans-mono
  ];
  environment = {
    pathsToLink = [ "/share/qti" ];
    sessionVariables = {
      QT_QPA_PLATFORMTHEME = "qt6ct";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QSG_USE_SIMPLE_ANIMATION_DRIVER = "0";
    };
  };
  system.activationScripts.me =
    let
      username = "me";
      homeDirectory = "/home/${username}";
      hyprlandConfFile = pkgs.writeText "hyprland.conf" (pkgs.callPackage ./config/hyprland.nix args);
      ghosttyConfFile = pkgs.writeText "config" (pkgs.callPackage ./config/ghostty.nix args);
    in
    ''
      echo "Setting up hyprland.conf for user: ${username}"
      userGroup=$(${pkgs.coreutils}/bin/id -gn ${username})
      ${pkgs.coreutils}/bin/mkdir -p "${homeDirectory}/.config/hypr"
      ${pkgs.coreutils}/bin/ln -sf "${hyprlandConfFile}" "${homeDirectory}/.config/hypr/hyprland.conf"
      ${pkgs.coreutils}/bin/mkdir -p "${homeDirectory}/.config/ghostty"
      ${pkgs.coreutils}/bin/ln -sf "${ghosttyConfFile}" "${homeDirectory}/.config/ghostty/config"
    '';
  xdg.portal = {
    enable = true;
    config = {
      common.default = [
        "hyprland"
        "gtk"
      ];
    };
    extraPortals = with pkgs; [
      inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland
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
