{
  lib,
  stdenv,
  fetchurl,
  glibc,
  icu,
  makeWrapper,
  patchelf,
}:

stdenv.mkDerivation {
  pname = "aspire-cli";
  version = "daily";

  src = fetchurl {
    url = "https://aka.ms/dotnet/9/aspire/ga/daily/aspire-cli-linux-x64.tar.gz";
    hash = "sha512-zMUT7Y2r0vtXGwdSBnCiibBTsk0BgwVSPu7IlBec34GWvn16AmuFvjxsQ02WIirGs7bO49GzrrQOPymwRkoJbw==";
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
      --set-rpath "${lib.makeLibraryPath [glibc icu]}" \
      "$out/libexec/aspire"

    makeWrapper "$out/libexec/aspire" "$out/bin/aspire" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [icu]}"

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
