{
  lib,
  stdenv,
  nodejs_24,
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
  makeWrapper,
  autoPatchelfHook,
  which,
  pciutils,
  # llama-server for the Local Model. Override with a CUDA/ROCm/Vulkan build
  # for GPU offload, or null to let the app download its own runtime.
  llama-cpp,
  # Upstream checkout (flake input).
  src,
  # Defaults for the server's environment, e.g. ROCm device selection.
  wrapperEnv ? { },
  # The Agent SDK's own Claude Code binary (~240 MB). Without it, the Claude
  # subscription provider needs a `claude` on PATH at least as new as the SDK's.
  bundleClaudeCode ? true,
}:

let
  packageJson = lib.importJSON "${src}/package.json";
  nodePlatform = stdenv.hostPlatform.node.platform;
  nodeArch = stdenv.hostPlatform.node.arch;
  nodejs = nodejs_24;
  pnpm = pnpm_10;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "marinara-engine";
  inherit (packageJson) version;
  inherit src;

  # The repo .npmrc pins the store inside the checkout and pnpm-workspace.yaml
  # asks pnpm to fetch its exact pinned version; neither works in the sandbox.
  postPatch = ''
    sed -i '/^store-dir=/d; /^virtual-store-dir=/d' .npmrc
    sed -i 's/^managePackageManagerVersions: true/managePackageManagerVersions: false/' pnpm-workspace.yaml
  '';

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      postPatch
      ;
    inherit pnpm;
    fetcherVersion = 3;
    hash = "sha256-s19xFQW4rXsRkFENj8DRMyD3xKDmag2+7vT8iteU0g8=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  # Node addons find libstdc++ and libgcc_s already loaded by node, and patching
  # sharp's prebuilt libvips corrupts it (segfault on load). Only the SDK's
  # standalone Claude Code executable needs an interpreter and rpath.
  dontAutoPatchelf = true;
  postFixup = lib.optionalString (bundleClaudeCode && stdenv.hostPlatform.isLinux) ''
    autoPatchelf $out/lib/marinara-engine/node_modules/.pnpm/@anthropic-ai+claude-agent-sdk-*
  '';

  env.MARINARA_GIT_COMMIT = "nix";

  buildPhase = ''
    runHook preBuild

    # onnxruntime-node's install script only downloads optional CUDA providers;
    # its CPU binding ships in the tarball, so it is left unbuilt.
    pnpm rebuild esbuild sharp protobufjs
    pnpm --filter @marinara-engine/shared build
    pnpm --filter @marinara-engine/server --filter @marinara-engine/client run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Reinstall only the server's production dependencies: no dev tooling, and
    # none of the client's, whose code is already bundled into its dist.
    rm -rf node_modules packages/*/node_modules
    CI=true pnpm --offline --ignore-scripts --prod install --frozen-lockfile \
      --filter @marinara-engine/server...
    # Same as the Docker image: the server uses onnxruntime-node, not the WASM build.
    rm -rf node_modules/.pnpm/onnxruntime-web@*
    # Native bindings shipped for every platform; keep the host's.
    for d in node_modules/.pnpm/onnxruntime-node@*/node_modules/onnxruntime-node/bin/napi-v6/*/* \
      node_modules/.pnpm/@earendil-works+pi-tui@*/node_modules/@earendil-works/pi-tui/native/*/prebuilds/*; do
      case $d in */${nodePlatform}/${nodeArch} | */${nodePlatform}-${nodeArch}) ;; *) rm -rf "$d" ;; esac
    done
    ${lib.optionalString (!bundleClaudeCode) ''
      rm -rf node_modules/.pnpm/@anthropic-ai+claude-agent-sdk-*
    ''}
    find node_modules packages/*/node_modules -xtype l -delete

    app=$out/lib/marinara-engine
    mkdir -p $app/packages/{shared,server,client} $out/bin
    cp -r package.json node_modules README.md docs scripts $app/
    for p in shared server client; do
      cp -r packages/$p/package.json packages/$p/dist $app/packages/$p/
      if [ -d packages/$p/node_modules ]; then
        cp -r packages/$p/node_modules $app/packages/$p/
      fi
    done

    # The server's default data dir and .env live next to the install, which is
    # read-only in the store. Default both to a per-user directory instead.
    # The Local Model runtime it would otherwise download is a generic Linux
    # build that cannot run on NixOS, so use nixpkgs' llama-server instead. The
    # server finds it with `which` and detects GPUs with `lspci`.
    makeWrapper ${lib.getExe nodejs} $out/bin/marinara-engine \
      --add-flags $app/packages/server/dist/index.js \
      --run 'export DATA_DIR="''${DATA_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/marinara-engine}"' \
      --run 'export MARINARA_ENV_FILE="''${MARINARA_ENV_FILE:-$DATA_DIR/.env}"' \
      --run 'mkdir -p "$DATA_DIR"' \
      --set-default NODE_ENV production \
      ${lib.concatStringsSep " " (
        lib.mapAttrsToList (k: v: "--set-default ${k} ${lib.escapeShellArg v}") wrapperEnv
      )} \
      ${lib.optionalString (llama-cpp != null) ''
        --prefix PATH : ${
          lib.makeBinPath (
            [
              llama-cpp
              which
            ]
            ++ lib.optionals stdenv.hostPlatform.isLinux [ pciutils ]
          )
        } \
        --set-default MARINARA_SIDECAR_USE_SYSTEM_LLAMA_SERVER true''}

    makeWrapper ${lib.getExe nodejs} $out/bin/mari \
      --add-flags $app/packages/server/dist/bin/mari.js \
      --run 'export DATA_DIR="''${DATA_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/marinara-engine}"' \
      --run 'export MARINARA_ENV_FILE="''${MARINARA_ENV_FILE:-$DATA_DIR/.env}"'

    runHook postInstall
  '';

  meta = {
    description = packageJson.description;
    homepage = "https://github.com/Pasta-Devs/Marinara-Engine";
    license = lib.licenses.agpl3Only;
    mainProgram = "marinara-engine";
    platforms = lib.platforms.unix;
  };
})
