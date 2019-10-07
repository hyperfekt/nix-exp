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
          version = "5.2.2019.10.07";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs";
            rev = "b83dba0d3fde8d424a274a0936d9c436d770b3aa";
            sha256 = "0vgyf0cpdcs2ldh6k060hc4x1hbxrv5r2iz4lgg3ak2w9k2a8bpk";
          };
        }; };
        bcachefs-tools = super.bcachefs-tools.overrideAttrs (oldAttrs: rec {
          version = "2019-10-04";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs-tools";
            rev = "62f5e4fa67dde8255fa18a06d5354cdca02b6fc7";
            sha256 = "1wcjz88jxnak45x8lfhblgrarrbiyygrdf2vjrnqx9qj38315ddz";
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
