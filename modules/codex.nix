# NOTE: To update this package, run:
#   ./modules/update-codex.sh
# Or specify a version:
#   ./modules/update-codex.sh 0.155.0
#
# Built from the npm prebuilt rather than source: upstream's flake cannot build
# the workspace (stale/missing cargoLock.outputHashes, undeclared native deps,
# and a v8 "sandbox" prebuilt denoland does not publish).
{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  bubblewrap,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "codex";
  version = "0.154.0";

  src = fetchzip {
    url = "https://registry.npmjs.org/@openai/codex/-/codex-${finalAttrs.version}-linux-x64.tgz";
    hash = "sha256-FeS1Sfij0+LykTHFl7b7Uue2Sm+WQcsoAkik+GAI9HQ=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;
  # The binaries are static-pie musl builds; there is nothing to patch, and
  # stripping them breaks the embedded resources.
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    # Keep the vendor layout intact -- codex resolves codex-path/rg and
    # codex-resources/{bwrap,zsh} relative to its own executable.
    mkdir -p $out/lib/codex $out/bin
    cp -r vendor/x86_64-unknown-linux-musl/. $out/lib/codex/
    chmod -R u+w $out/lib/codex
    # codex warns and falls back to its bundled bwrap if it cannot find
    # bubblewrap on PATH. The wrapper execs the real binary, so it still
    # resolves its own resources relative to $out/lib/codex.
    makeWrapper $out/lib/codex/bin/codex $out/bin/codex \
      --prefix PATH : ${lib.makeBinPath [ bubblewrap ]}

    runHook postInstall
  '';

  passthru.updateScript = ./update-codex.sh;

  meta = {
    description = "OpenAI Codex command-line interface";
    homepage = "https://github.com/openai/codex";
    downloadPage = "https://www.npmjs.com/package/@openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
