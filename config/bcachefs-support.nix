{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "bcachefs" ];
  boot.initrd.supportedFilesystems = [ "bcachefs" ];
  security.pam.defaults = "session required pam_keyinit.so force revoke";
}