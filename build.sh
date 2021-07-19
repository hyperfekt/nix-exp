#! /usr/bin/env bash
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config="${BASH_SOURCE%/*}/installation-cd-bcachefs-graphical-plasma5-de-git.nix" --cores 4 -I nixpkgs=channel:nixos-21.05 --show-trace --keep-going
