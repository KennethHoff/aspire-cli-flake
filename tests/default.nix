# Not gonna lie, these tests are entirely AI generated, and I don't really know what these are testing.
{
  pkgs,
  self,
}: let
  system = pkgs.stdenv.hostPlatform.system;
  packages = self.packages.${system};
in {
  readme =
    pkgs.runCommand "aspire-cli-readme-test" {
      nativeBuildInputs = [pkgs.coreutils pkgs.gnugrep];
      readme = ./../README.md;
      aspire = packages.aspire-cli;
    } ''
        set -euo pipefail

        test -f "$readme"

        grep -q "nix run \\." "$readme"
        grep -q "nix build \\.#aspire-cli" "$readme"
        grep -q "aspire-cli\\.url = \"github:kennethhoff/aspire-cli-flake\"" "$readme"
        grep -q "x86_64-linux" "$readme"
        grep -q "aspire-cli-stable" "$readme"
        grep -q "aspire-cli-staging" "$readme"
        grep -q "aspire-cli-dev" "$readme"
        grep -q "override" "$readme"

        # Ensure the packaged binary exists.
        test -x "$aspire/bin/aspire"

        mkdir -p "$out"
    '';

  versionOverride =
    pkgs.runCommand "aspire-cli-version-override-test" {
      nativeBuildInputs = [pkgs.coreutils pkgs.gnugrep];
      baseUrl = packages.aspire-cli-stable.src.url;
      overriddenUrl =
        (packages.aspire-cli-stable.override {
          version = "0.0.0-test";
          hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        }).src.url;
    } ''
      set -euo pipefail

      echo "$overriddenUrl" | grep -q "0\.0\.0-test"

      mkdir -p "$out"
    '';

  channelPackages =
    pkgs.runCommand "aspire-cli-channel-test" {
      nativeBuildInputs = [pkgs.coreutils];
      stable = packages.aspire-cli-stable;
      staging = packages.aspire-cli-staging;
      dev = packages.aspire-cli-dev;
    } ''
      set -euo pipefail

      test -x "$stable/bin/aspire"
      test -x "$staging/bin/aspire"
      test -x "$dev/bin/aspire"

      mkdir -p "$out"
    '';

  stagingBundleRuntimePath =
    pkgs.runCommand "aspire-cli-staging-runtime-path-test" {
      nativeBuildInputs = [pkgs.coreutils pkgs.gnugrep];
      staging = packages.aspire-cli-staging;
    } ''
      set -euo pipefail

      export HOME="$PWD/home"
      rm -rf "$HOME"
      mkdir -p "$HOME"

      "$staging/bin/aspire" update --debug --non-interactive >stdout 2>stderr || true

      grep -q "$HOME/.local/state/aspire-cli" stderr
      grep -q ".aspire-bundle-lock" stderr
      if grep -q "/nix/store/.*\.aspire-bundle-lock" stderr; then
        echo "bundle lock unexpectedly used /nix/store" >&2
        exit 1
      fi

      mkdir -p "$out"
    '';

  # Regression: the openssl pin is a Linux-only TLS workaround. Applying its
  # overlay on Darwin injected a foreign-nixpkgs openssl into the Darwin stdenv
  # bootstrap, tripping `isBuiltByBootstrapFilesCompiler` and breaking eval of
  # the whole package set. The overlay must be active only on Linux: building
  # this check uses `pkgs.stdenv`, so it eval-fails on Darwin if the overlay
  # ever leaks back in; the drvPath contract also guards the Linux pin.
  opensslOverlayPlatformScope = let
    nativeOpenssl = (import pkgs.path {inherit system;}).openssl;
    # Linux: overlay active -> pinned openssl differs from native.
    # Darwin: overlay no-op  -> openssl identical to native.
    contractHolds =
      if pkgs.stdenv.hostPlatform.isLinux
      then pkgs.openssl.drvPath != nativeOpenssl.drvPath
      else pkgs.openssl.drvPath == nativeOpenssl.drvPath;
  in
    pkgs.runCommand "aspire-cli-openssl-overlay-scope-test" {
      inherit contractHolds;
    } ''
      set -euo pipefail

      test "$contractHolds" = "1"

      mkdir -p "$out"
    '';
}
