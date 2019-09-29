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
          version = "5.2.2019.09.26";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs";
            rev = "7ee280070625b0cf2528ebc461371976efa39c51";
            sha256 = "0g29d01qfdxgfv56rhqn71s93f8iqbsyvmak93b29dmb8ym2b3v8";
          };
        }; };
        bcachefs-tools = super.bcachefs-tools.overrideAttrs (oldAttrs: rec {
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs-tools";
            rev = "db39aa3e1b528db3b9d731c3b054f27411e1e1a9";
            sha256 = "19x7n51yr30dd9rrvji3xk3rij5xd8b86qiym9alpkbbyrz7h956";
          };
          version = "2019-09-25";
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
