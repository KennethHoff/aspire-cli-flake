{
  lib,
  stdenv,
  system,
  fetchurl,
  glibc,
  icu,
  openssl,
  makeWrapper,
  patchelf,
  version,
  fileVersion ? version,
  hash,
}:
let
  platformMap = {
    x86_64-linux = "linux-x64";
    aarch64-linux = "linux-arm64";
    x86_64-darwin = "osx-x64";
    aarch64-darwin = "osx-arm64";
  };
  platform = platformMap.${system};
  isLinux = stdenv.hostPlatform.isLinux;
  isDarwin = stdenv.hostPlatform.isDarwin;
in
stdenv.mkDerivation {
  pname = "aspire-cli";
  inherit version;

  src = fetchurl {
    url = "https://ci.dot.net/public/aspire/${version}/aspire-cli-${platform}-${fileVersion}.tar.gz";
    inherit hash;
  };

  nativeBuildInputs = lib.optionals isLinux [makeWrapper patchelf];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    tar -xzf "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -D -m0755 aspire "$out/libexec/aspire"

    ${lib.optionalString isLinux ''
      patchelf \
        --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" \
        --set-rpath "${lib.makeLibraryPath [glibc icu openssl]}" \
        "$out/libexec/aspire"

      makeWrapper "$out/libexec/aspire" "$out/bin/aspire" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [icu openssl]}"
    ''}

    ${lib.optionalString isDarwin ''
      mkdir -p "$out/bin"
      ln -s "$out/libexec/aspire" "$out/bin/aspire"
    ''}

    runHook postInstall
  '';

  meta = {
    description = ".NET Aspire CLI";
    homepage = "https://learn.microsoft.com/dotnet/aspire/";
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "aspire";
  };
}
