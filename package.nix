{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  versionCheckHook,
}:

let
  # Written by update.sh from the npm registry.
  release = lib.importJSON ./release.json;
  platform = release.platforms.${stdenv.hostPlatform.system}
    or (throw "polar-cli: no binary for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "polar-cli";
  inherit (release) version;

  # @polar-sh/cli only picks one of these per-platform packages; each holds
  # a single prebuilt executable, bin/polar.
  src = fetchurl {
    inherit (platform) url hash;
  };
  sourceRoot = "package";

  nativeBuildInputs = [ autoPatchelfHook ];

  # The executable carries its program after the ELF image; strip would cut it.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/polar $out/bin/polar
    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Polar's CLI: webhook forwarding, sample events, sessions";
    homepage = "https://polar.sh/docs/integrate/cli";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames release.platforms;
    mainProgram = "polar";
  };
}
