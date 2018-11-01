{ config, pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix # Include the results of the hardware scan.
      ./osprobe.nix # Scan system for installed OS and add them to GRUB
      ./bcachefs-support.nix
      ./source-based.nix
    ];
  
    networking.networkmanager.enable = true;
}
