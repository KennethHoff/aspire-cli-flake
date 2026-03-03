{
  description = "Nix flake for the .NET Aspire CLI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = nixpkgs.legacyPackages.${system};
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

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt);
    };
}
