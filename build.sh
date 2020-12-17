#! /usr/bin/env bash
set -e
nix-channel --add https://nixos.org/channels/nixos-20.09 nixos
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --update
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config="${BASH_SOURCE%/*}/installation-cd-bcachefs-graphical-plasma5-de-git.nix" --cores 4
