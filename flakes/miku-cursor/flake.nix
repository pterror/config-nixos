{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: let
    forAllSystems = with nixpkgs.lib; f: foldAttrs mergeAttrs { }
      (map (s: { ${s} = f s; }) systems.flakeExposed);
  in {
    packages = forAllSystems (system: rec {
      unicorn-scribbles = nixpkgs.legacyPackages.${system}.stdenv.mkDerivation {
        name = "unicorn-scribbles";
        version = "1.0.0";
        src = "https://www.dafont.com/unicorn-scribbles.font";
        url = "https://dl.dafont.com/dl/?f=unicorn_scribbles";
        sha256 = "a485afeaad61c9d8488a5363a34404336ae8b758fdf383c9556fcd64a6736202";
        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/fonts/opentype
          mv $downloadedFile $out/share/fonts/opentype/UnicornScribbles.otf
          runHook postInstall
        '';
        meta = {
          homepage = "https://www.dafont.com/unicorn-scribbles.font";
          description = "A typeface specially designed for user interfaces";
          #license = nixpkgs.lib.licenses.unfree;
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      default = unicorn-scribbles;
    });
  };
}
