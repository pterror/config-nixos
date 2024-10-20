{
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nix-gaming.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    impermanence.url = github:nix-community/impermanence;
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    quickshell.url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";
    qti.url = "git+https://github.com/pterror/qti?submodules=1";
    qti.inputs.nixpkgs.follows = "nixpkgs";
    nix-gaming.url = github:fufexan/nix-gaming;
    unicorn-scribbles-font.url = path:./flakes/unicorn-scribbles-font;
    unicorn-scribbles-font.inputs.nixpkgs.follows = "nixpkgs";
    miku-cursor.url = path:./flakes/miku-cursor;
    miku-cursor.inputs.nixpkgs.follows = "nixpkgs";
    hwfetch.url = github:morr0ne/hwfetch;
    hwfetch.inputs.nixpkgs.follows = "nixpkgs";
    asciinema.url = github:asciinema/asciinema;
    asciinema.inputs.nixpkgs.follows = "nixpkgs";
    verdi.url = github:pterror/verdi;
    verdi.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, impermanence, ... }@inputs: {
    nixosConfigurations.pc = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; my-config = import ./my-config.nix; };
      modules = [
        impermanence.nixosModules.impermanence
        ./configuration.nix
      ];
    };
  };
}

