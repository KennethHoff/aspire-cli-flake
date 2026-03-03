{
  description = "Nix flake for the .NET Aspire CLI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux"];

    forAllSystems = f:
      nixpkgs.lib.genAttrs supportedSystems (system: f system);

    versions = import ./versions.nix;
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      mkAspire = channel:
        pkgs.callPackage ./package.nix {
          inherit (versions.${channel}) version url hash;
        };
    in {
      aspire-cli-stable = mkAspire "stable";
      aspire-cli-staging = mkAspire "staging";
      aspire-cli-dev = mkAspire "dev";
      aspire-cli = self.packages.${system}.aspire-cli-stable;
      default = self.packages.${system}.aspire-cli;
    });

    checks = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in
      import ./tests {inherit pkgs self;});

    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/aspire";
      };
    });

    devShells = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.mkShell {
        packages = [
          self.packages.${system}.aspire-cli-stable
          self.packages.${system}.aspire-cli-staging
          self.packages.${system}.aspire-cli-dev
        ];
      };
    });

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
  };
}
