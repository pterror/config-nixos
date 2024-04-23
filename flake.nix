{
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
    hyprspace.url = "github:KZDKM/Hyprspace";
    hyprspace.inputs.hyprland.follows = "hyprland";
    quickshell.url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";
    nix-gaming.url = "github:fufexan/nix-gaming";
    unicorn-scribbles-font.url = "path:./flakes/unicorn-scribbles-font";
    miku-cursor.url = "path:./flakes/miku-cursor";
  };
  outputs = { self, nixpkgs, impermanence, ... }@inputs: {
    nixosConfigurations.pc = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        impermanence.nixosModules.impermanence
        ./configuration.nix
      ];
    };
  };
}

