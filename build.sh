#! /usr/bin/env bash
set -e
sudo nix-channel --add https://nixos.org/channels/nixos-19.09 nixos
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
sudo nix-channel --update
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config="${BASH_SOURCE%/*}/installation-cd-bcachefs-graphical-kde-git-de.nix" --cores 4
