# Aspire CLI

This is a Nix Flake for the [Aspire](https://aspire.dev) CLI tool.

## Usage

Run from this repo:

```bash
nix run .
```

Build the package:

```bash
nix build .#aspire-cli
```

## Development Flake

Add this flake as an input and include the package in your dev shell:

### Native

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    aspire-cli.url = "github:kennethhoff/aspire-cli-flake";
  };

  outputs = {
    self,
    nixpkgs,
    aspire-cli,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        aspire-cli.packages.${system}.aspire-cli
      ];
    };
  };
}
```

Then run `nix develop` and use `aspire`.

### With flake-utils

If your project uses `flake-utils`, you can wire it up like this:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    aspire-cli.url = "github:kennethhoff/aspire-cli-flake";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    aspire-cli,
    ...
  }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        packages = [
          aspire-cli.packages.${system}.aspire-cli
        ];
      };
    });
}
```

### flake-utils

## Notes

- Targets `x86_64-linux` (upstream tarball: `aspire-cli-linux-x64.tar.gz`).
