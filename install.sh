#! /usr/bin/env bash
NIXOS_CONFIG=/mnt/cfg/bismuth.nix nixos-install -v -I nixpkgs=/mnt/cfg/patched --max-jobs 8 --no-channel-copy --keep-going
