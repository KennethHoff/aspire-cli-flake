# Not gonna lie, these tests are entirely AI generated, and I don't really know what these are testing.
{
  pkgs,
  self,
}: {
  readme =
    pkgs.runCommand "aspire-cli-readme-test" {
      nativeBuildInputs = [pkgs.coreutils pkgs.gnugrep];
      readme = ./../README.md;
      aspire = self.packages.${pkgs.stdenv.hostPlatform.system}.aspire-cli;
    } ''
        set -euo pipefail

        test -f "$readme"

        # Keep these in sync with README usage examples.
        grep -q "nix run \\." "$readme"
        grep -q "nix build \\.#aspire-cli" "$readme"
        grep -q "aspire-cli\\.url = \"github:kennethhoff/aspire-cli-flake\"" "$readme"
        grep -q "flake-utils\\.url = \"github:numtide/flake-utils\"" "$readme"
        grep -q "x86_64-linux" "$readme"
        grep -q "Overriding The Aspire CLI Version" "$readme"
        grep -q "override" "$readme"
        grep -q "version" "$readme"
        grep -q "hash" "$readme"
        grep -q "<aspire-version>" "$readme"
        grep -q "<nix-hash>" "$readme"
        grep -q '\`-**\`' "$readme"
      grep -q "nix eval --raw \\.#packages\\.x86_64-linux\\.aspire-cli\\.version" "$readme"
      grep -q "https://ci\\.dot\\.net/public/aspire/<version>/aspire-cli-linux-x64-<version>\\.tar\\.gz" "$readme"
      grep -q "curl -L -I https://aka\\.ms/dotnet/9/aspire/qa/aspire-cli-linux-x64\\.tar\\.gz" "$readme"
      grep -q "curl -L -I https://aka\\.ms/dotnet/9/aspire/daily/aspire-cli-linux-x64\\.tar\\.gz" "$readme"

        # Ensure the packaged binary exists.
        test -x "$aspire/bin/aspire"

        # (Don't execute in sandbox; Aspire CLI expects a writable cwd)
        mkdir -p "$out"
    '';

  versionOverride =
    pkgs.runCommand "aspire-cli-version-override-test" {
      # We only need to evaluate the derivation to assert the URL changes; no network required.
      nativeBuildInputs = [pkgs.coreutils pkgs.gnugrep];
      baseUrl = self.packages.${pkgs.stdenv.hostPlatform.system}.aspire-cli.src.url;
      overriddenUrl =
        (self.packages.${pkgs.stdenv.hostPlatform.system}.aspire-cli.override {
          version = "0.0.0-test";
          hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        }).src.url;
    } ''
      set -euo pipefail

      # The fetch URL must include the overridden version.
      echo "$baseUrl" | grep -q "13\.2\.0-preview\.1\.26120\.3"
      echo "$overriddenUrl" | grep -q "0\.0\.0-test"

      mkdir -p "$out"
    '';
}
