{
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
    pointfree-font.url = path:./flakes/pointfree-font;
    pointfree-font.inputs.nixpkgs.follows = "nixpkgs";
    string-literal-font.url = path:./flakes/string-literal-font;
    string-literal-font.inputs.nixpkgs.follows = "nixpkgs";
    modum-font.url = path:./flakes/modum-font;
    modum-font.inputs.nixpkgs.follows = "nixpkgs";
    miku-cursor.url = path:./flakes/miku-cursor;
    miku-cursor.inputs.nixpkgs.follows = "nixpkgs";
    stardust-telescope.url = github:StardustXR/telescope;
    stardust-telescope.inputs.nixpkgs.follows = "nixpkgs";
    # hwfetch.url = github:morr0ne/hwfetch;
    # hwfetch.inputs.nixpkgs.follows = "nixpkgs";
    # asciinema.url = github:asciinema/asciinema;
    # asciinema.inputs.nixpkgs.follows = "nixpkgs";
    # verdi.url = github:pterror/verdi;
    # verdi.inputs.nixpkgs.follows = "nixpkgs";
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

