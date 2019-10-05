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
          version = "5.2.2019.10.04";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs";
            rev = "ce9293e9d063f7f1a22209f9cc2f5cb7478e886c";
            sha256 = "1qznj4pj2syanpbl91arvpqpr3gjxkwcp24r1bqc8swx52sw6lwn";
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
