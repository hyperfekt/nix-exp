{
  nix.nixPath = options.nix.nixPath.default ++ ["nixpkgs-overlays=/etc/nixos/overlays"];
}