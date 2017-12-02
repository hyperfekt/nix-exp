{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "bcachefs" ];
}
