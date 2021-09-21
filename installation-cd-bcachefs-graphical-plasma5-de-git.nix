# A NixOS installation CD with support for bcache
# see https://nixos.wiki/wiki/Creating_a_NixOS_live_CD for details
{config, pkgs, ...}:
{
    imports = [
        <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-plasma5.nix>
        <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
        ./config/bcachefs-support.nix
        ./config/layout_de.nix
        ./config/cloudflare-dns.nix
        ./config/git.nix
        ./config/largetmpfs.nix
        ./config/fastbuildkernel.nix
    ];

    services.thermald.enable = true;

    isoImage.squashfsCompression = "zstd -Xcompression-level 3";

}
