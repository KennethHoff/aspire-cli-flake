{
  description = "Nix flake for the .NET Aspire CLI";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {pkgs, system, ...}: let
        versions = import ./versions.nix;

        mkAspire = channel:
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
      in {
        packages = {
          aspire-cli-stable = aspire.stable;
          aspire-cli-staging = aspire.staging;
          aspire-cli-dev = aspire.dev;
          aspire-cli = aspire.stable;
          default = aspire.stable;
        };

        apps.default = {
          type = "app";
          program = "${aspire.stable}/bin/aspire";
        };

        devShells.default = pkgs.mkShell {
          packages = builtins.attrValues aspire;
        };

        formatter = pkgs.nixfmt;
      };
    };
}
