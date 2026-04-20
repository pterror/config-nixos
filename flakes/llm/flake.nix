{
  description = "Local LLM inference via llama.cpp + ROCm (gfx1100 / 7900 XTX)";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      llama = pkgs.llama-cpp.override { rocmSupport = true; };

      rocmEnv = {
        # RDNA3 (gfx1100) is not always auto-detected by ROCm
        HSA_OVERRIDE_GFX_VERSION = "11.0.0";
        # Prevents occasional hangs on RDNA3
        HSA_ENABLE_SDMA = "0";
        # Restrict HIP to GPU only — CPU appears as a ROCm HSA agent otherwise
        HIP_VISIBLE_DEVICES = "0";
      };

      mkServer = { name, port, ctxSize, parallel ? 2 }:
        pkgs.writeShellScriptBin "serve-${name}" ''
          export HSA_OVERRIDE_GFX_VERSION=${rocmEnv.HSA_OVERRIDE_GFX_VERSION}
          export HSA_ENABLE_SDMA=${rocmEnv.HSA_ENABLE_SDMA}
          export HIP_VISIBLE_DEVICES=${rocmEnv.HIP_VISIBLE_DEVICES}
          model="''${LLM_MODEL_PATH:-''${1:?}}"
          exec ${llama}/bin/llama-server \
            --model "$model" \
            --n-gpu-layers 999 \
            --ctx-size ${toString ctxSize} \
            --parallel ${toString parallel} \
            --flash-attn on \
            --host 127.0.0.1 \
            --port ${toString port}
        '';

      # Qwen3-35B-A3B: Q4_K_S (~20GB weights), ~3.5GB KV headroom
      # ctx 8192 uses ~3.1GB KV — safe with compositor overhead
      serve-qwen = mkServer { name = "qwen"; port = 8080; ctxSize = 8192; };

      # Gemma 4 26B-A4B: Q4_K_M (~18.7GB weights), ~4.9GB KV headroom
      # ctx 12288 uses ~4.6GB KV — better context than Q5_K_M (6.4K) for RP
      serve-gemma = mkServer { name = "gemma"; port = 8081; ctxSize = 12288; };

    in {
      packages.${system} = {
        inherit llama serve-qwen serve-gemma;
        default = llama;
      };

      apps.${system} = {
        serve-qwen  = { type = "app"; program = "${serve-qwen}/bin/serve-qwen"; };
        serve-gemma = { type = "app"; program = "${serve-gemma}/bin/serve-gemma"; };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ llama serve-qwen serve-gemma ];
        env = rocmEnv;
      };
    };
}
