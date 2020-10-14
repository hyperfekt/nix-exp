{ pkgs ? import <nixpkgs> {}}:
(pkgs.callPackage (builtins.fetchurl "https://raw.githubusercontent.com/NixOS/nixpkgs/b73041d9a6394be6af1667587a1ab8f705ded3ba/pkgs/tools/backup/restic/default.nix") {}).overrideAttrs (old: { doCheck = false; })
