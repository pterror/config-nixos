# NOTE: To update this package, run:
#   ./modules/update-claude-code.sh
# Or specify a version:
#   ./modules/update-claude-code.sh 2.1.33
{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  bubblewrap,
  procps,
  socat,
  glibc,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "claude-code";
  version = "2.1.143";

  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-${finalAttrs.version}.tgz";
    hash = "sha256-OfXj8/M7VBCSRSXCbd+8sAbcFgC3Ehu5RvaY3plZqGA=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [ glibc ];

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 claude $out/bin/claude
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --unset DEV \
      --prefix PATH : ${
        lib.makeBinPath (
          [ procps ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            bubblewrap
            socat
          ]
        )
      }
  '';

  passthru.updateScript = ./update-claude-code.sh;

  meta = {
    description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/anthropics/claude-code";
    downloadPage = "https://www.npmjs.com/package/@anthropic-ai/claude-code";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [
      adeci
      malo
      markus1189
      omarjatoi
      xiaoxiangmoe
    ];
    mainProgram = "claude";
  };
})
