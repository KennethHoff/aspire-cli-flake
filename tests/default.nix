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
}
