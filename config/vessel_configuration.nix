{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Scan system for installed OS and add them to GRUB
      ./osprobe.nix
    ];

  boot.loader.grub.device = "/dev/sda";
}
