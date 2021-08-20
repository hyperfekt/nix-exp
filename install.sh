#! /usr/bin/env bash
NIXOS_CONFIG=/mnt/cfg/bismuth.nix nixos-install -I nixpkgs=/mnt/cfg/patched --max-jobs 8 --cores 4 --show-trace "$@"
