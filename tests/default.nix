{
  pkgs,
  self,
}:

{
  readme = pkgs.runCommand "aspire-cli-readme-test" {
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

    # Ensure the packaged binary exists.
    test -x "$aspire/bin/aspire"

    # (Don't execute in sandbox; Aspire CLI expects a writable cwd)
    mkdir -p "$out"
  '';
}
