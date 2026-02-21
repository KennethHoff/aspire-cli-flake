{
  lib,
  stdenv,
  fetchurl,
  glibc,
  icu,
  openssl,
  makeWrapper,
  patchelf,
  version ? "13.2.0-preview.1.26120.3",
  hash ? "sha512-t0pR9dlWQNr4cFEg3ERpomTrnADXNpTzlxyDZcZwxQJGa0A9030PTOnybRvzho5VmkwoR2xuCIUyfdxAjM3iYQ==",
}:
stdenv.mkDerivation {
  pname = "aspire-cli";
  inherit version;

  src = fetchurl {
    url = "https://ci.dot.net/public/aspire/${version}/aspire-cli-linux-x64-${version}.tar.gz";
    inherit hash;
  };

  nativeBuildInputs = [makeWrapper patchelf];

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

    patchelf \
      --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" \
      --set-rpath "${lib.makeLibraryPath [glibc icu openssl]}" \
      "$out/libexec/aspire"

    makeWrapper "$out/libexec/aspire" "$out/bin/aspire" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [icu openssl]}"

    runHook postInstall
  '';

  meta = {
    description = ".NET Aspire CLI";
    homepage = "https://learn.microsoft.com/dotnet/aspire/";
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "aspire";
  };
}
