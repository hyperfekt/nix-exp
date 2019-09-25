# A NixOS installation CD with support for bcache
# see https://nixos.wiki/wiki/Creating_a_NixOS_live_CD for details
{config, pkgs, ...}:
{
    imports = [
        <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-kde-new-kernel.nix>
        <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
        ./config/bcachefs-support.nix
        ./config/git.nix
        ./config/layout_de.nix
        ./config/chroot_nix_fix.nix
    ];
}
