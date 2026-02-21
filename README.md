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

## Notes

- Targets `x86_64-linux` (upstream tarball: `aspire-cli-linux-x64.tar.gz`).
