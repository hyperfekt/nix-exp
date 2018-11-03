{ config, pkgs, ... }:

{
  imports =
    [
      ./bcachefs-support.nix
      ./unfree.nix
    ];
  
    networking.networkmanager.enable = true;
}