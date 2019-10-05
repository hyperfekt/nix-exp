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
          version = "5.2.2019.10.05";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs";
            rev = "ce9c3373f2936da244dc80e945e2dc944fd23fec";
            sha256 = "1xyjy6lx6rcdwl55lwz1lpv0f4h11wf8lcap42kwdxwh44vj7mph";
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
