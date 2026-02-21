# Aspire CLI

This is a Nix Flake for the [Aspire](https://aspire.dev) CLI tool.

## Contents

- [Usage](#usage)
- [Use this flake in your project](#use-this-flake-in-your-project)
- [Override the Aspire CLI version](#override-the-aspire-cli-version)
- [Notes](#notes)

## Usage

Run from this repo:

```bash
nix run .
```

Build the package:

```bash
nix build .#aspire-cli
```

## Use this flake in your project

Add this flake as an input and include the package in your dev shell.

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

## Override the Aspire CLI version

The package is parameterized by `version` and `hash` (the upstream tarball is fetched with `fetchurl`).

If you want to use a different Aspire CLI version, override both values:

Note: the version string includes a `-**` qualifier (for example `-preview...`), so be sure to use the full version from the upstream tarball URL.

When bumping to a specific release, copy the version segment from the upstream tarball URL format:
`https://ci.dot.net/public/aspire/<version>/aspire-cli-linux-x64-<version>.tar.gz`.

The following URLs are moving channels. You can resolve the full version by following redirects and reading the final `Location` header (the final URL contains the full version string):

```bash
# stable (latest)
curl -sL -o /dev/null -w '%{url_effective}\n' https://aka.ms/dotnet/9/aspire/ga/daily/aspire-cli-linux-x64.tar.gz \
  | sed -n 's#^.*/public/aspire/\([^/]*\)/.*#\1#p'

# staging (rc)
curl -sL -o /dev/null -w '%{url_effective}\n' https://aka.ms/dotnet/9/aspire/rc/daily/aspire-cli-linux-x64.tar.gz \
  | sed -n 's#^.*/public/aspire/\([^/]*\)/.*#\1#p'

# dev (daily)
curl -sL -o /dev/null -w '%{url_effective}\n' https://aka.ms/dotnet/9/aspire/daily/aspire-cli-linux-x64.tar.gz \
  | sed -n 's#^.*/public/aspire/\([^/]*\)/.*#\1#p'
```

```nix
let
  aspire = aspire-cli.packages.${system}.aspire-cli.override {
    version = "<aspire-version>";
    hash = "<nix-hash>";
  };
in {
  devShells.${system}.default = pkgs.mkShell {
    packages = [aspire];
  };
}
```

To get the correct `hash` for a new version, run a build once and copy the `got: ...` hash from the failure message.

## Notes

- Targets `x86_64-linux` (upstream tarball: `aspire-cli-linux-x64.tar.gz`).
