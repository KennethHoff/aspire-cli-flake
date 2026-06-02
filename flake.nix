{
  description = "Nix flake for the .NET Aspire CLI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Pinned solely to source OpenSSL 3.6.1 (see the overlay below). This rev
    # still carries openssl 3.6.1; nixos-unstable has since moved to 3.6.2.
    nixpkgs-openssl.url = "github:NixOS/nixpkgs/549bd84d6279f9852cae6225e372cc67fb91a4c1";
  };

  outputs =
    { self, nixpkgs, nixpkgs-openssl, ... }:
    let
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      # Workaround for the Aspire CLI's DCP TLS handshake failing under OpenSSL
      # 3.6.2 on Linux. `aspire run` trusts a self-signed localhost dev cert for
      # the AppHost<->DCP control-plane connection; under 3.6.2 the AppHost
      # crashes on startup with "SSL connection could not be established /
      # unexpected EOF" (the "PartiallyFailedToTrustTheCertificate" line on
      # NixOS is benign — it shows up on 3.6.1 too). OpenSSL 3.6.1 works.
      #
      # This was isolated by bisection: holding everything else at current
      # (aspire-cli 13.3.x, dotnet-sdk 10.0.300, nixpkgs nixos-unstable) and
      # flipping ONLY the openssl this CLI links flips boot<->crash. The CLI
      # loads openssl via this package's RPATH/LD_LIBRARY_PATH (see package.nix),
      # so pinning it here fixes the CLI without touching the consumer's nixpkgs.
      #
      # NOTE: this is NOT microsoft/aspire#13219 (SSL_CERT_DIR not propagated) —
      # that was fixed by PR #13221 in the Aspire 13.1 milestone, and the CLI
      # versions shipped here (>=13.1) already include it. The root cause is an
      # OpenSSL 3.6.1->3.6.2 cert/TLS-verification behaviour change; the exact
      # upstream change has not been pinned down yet.
      #
      # TODO(~2026-07): revisit this pin (added 2026-05-31). Re-test by dropping
      # `nixpkgs-openssl` + this overlay and `aspire run`-ing an AppHost on Linux
      # — if a newer OpenSSL (>3.6.2) or Aspire CLI boots cleanly, delete the
      # input and overlay. If still broken, narrow the OpenSSL change (diff
      # 3.6.1..3.6.2 CHANGES.md) and file an upstream issue. Don't let this pin
      # rot — it freezes the CLI's OpenSSL and misses its security updates.
      #
      # Linux-only: applying this overlay on Darwin injects an openssl built by
      # a different nixpkgs's bootstrap compiler into the Darwin stdenv, which
      # trips its `isBuiltByBootstrapFilesCompiler` assertion — eval fails before
      # anything builds. `optionalAttrs` makes it a no-op on Darwin (native
      # openssl), which doesn't need the workaround anyway.
      opensslOverlay = final: prev:
        nixpkgs.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
          openssl = nixpkgs-openssl.legacyPackages.${prev.stdenv.hostPlatform.system}.openssl;
        };

      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ opensslOverlay ];
            };
            inherit system;
          }
        );
    in
    {
      packages = forAllSystems (
        { pkgs, system }:
        let
          versions = import ./versions.nix;

          mkAspire =
            channel:
            pkgs.callPackage ./package.nix {
              inherit system;
              inherit (versions.${channel}) version;
              inherit (versions.${channel}) fileVersion;
              hash = versions.${channel}.hashes.${system};
            };

          aspire = {
            stable = mkAspire "stable";
            staging = mkAspire "staging";
            dev = mkAspire "dev";
          };
        in
        {
          aspire-cli-stable = aspire.stable;
          aspire-cli-staging = aspire.staging;
          aspire-cli-dev = aspire.dev;
          aspire-cli = aspire.stable;
          default = aspire.stable;
        }
      );

      apps = forAllSystems (
        { pkgs, system }:
        let
          versions = import ./versions.nix;
          aspire = pkgs.callPackage ./package.nix {
            inherit system;
            inherit (versions.stable) version;
            inherit (versions.stable) fileVersion;
            hash = versions.stable.hashes.${system};
          };
        in
        {
          default = {
            type = "app";
            program = "${aspire}/bin/aspire";
          };
        }
      );

      devShells = forAllSystems (
        { pkgs, system }:
        let
          versions = import ./versions.nix;

          mkAspire =
            channel:
            pkgs.callPackage ./package.nix {
              inherit system;
              inherit (versions.${channel}) version;
              inherit (versions.${channel}) fileVersion;
              hash = versions.${channel}.hashes.${system};
            };
        in
        {
          default = pkgs.mkShell {
            packages = [
              (mkAspire "stable")
              (mkAspire "staging")
              (mkAspire "dev")
            ];
          };
        }
      );

      checks = forAllSystems (
        { pkgs, ... }:
        import ./tests/default.nix {
          inherit pkgs self;
        }
      );

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt);
    };
}
