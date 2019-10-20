{ pkgs, lib, config, ...}:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  disabledModules = [ "tasks/filesystems/zfs.nix" ];

  options.security.pam.services = with lib; mkOption {
    type = types.loaOf (types.submodule {
      config.text = mkDefault (mkAfter "session required pam_keyinit.so force revoke");
    });
  };

  config = {
    nixpkgs.overlays = [ (
      self: super: {
        linux_testing_bcachefs = super.linux_testing_bcachefs.override { argsOverride = {
          modDirVersion = "5.2.0";
          version = "5.2.2019.10.20";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs";
            rev = "82ea7be49f88ffd6811eb38c8f13ad423ba06817";
            sha256 = "0ygpn3ak9016mv8542m3yqklnrjjrmfz7n2f1xa6crbgks5i852q";
          };
        }; };
        bcachefs-tools = super.bcachefs-tools.overrideAttrs (oldAttrs: rec {
          version = "2019-10-16";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs-tools";
            rev = "3c810611c1d1c9299d2200914cf279e92fa80d72";
            sha256 = "0b7zq3c7vcc9qi6yanz5vin3z034jb1xjy5ci6jl2nq0nzh4d0il";
          };
        });
      }
    ) ];

    boot.supportedFilesystems = [ "bcachefs" ];

    boot.kernelPatches = [
      {
        name = "bcachefs-acl";
        patch = null;
        extraConfig = ''
          BCACHEFS_POSIX_ACL y
        '';
      }
      {
        name = "bcachefs-debug";
        patch = null;
        extraConfig = ''
          BCACHEFS_DEBUG y
        '';
      }
    ];
  };
}
