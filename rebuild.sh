#!/usr/bin/env bash
resolvconf="$(cat /etc/resolv.conf)";
nixos-enter -c "echo '$resolvconf' > /etc/resolv.conf; nixos-rebuild boot -I nixpkgs=/cfg/patched -I nixos-config=/cfg/bismuth.nix --show-trace --option sandbox false" # can't create recursive user namespaces
