{ pkgs, lib, config, ...}:
{
  disabledModules = [ "tasks/filesystems/zfs.nix" ];

  imports = [ ./debugkernel.nix ];

  options.security.pam.services = with lib; mkOption {
    type = types.loaOf (types.submodule {
      config.text = mkDefault (mkAfter "session required pam_keyinit.so force revoke");
    });
  };

  config = {
    nixpkgs.overlays = [ (
      self: super: {
        linux_testing_bcachefs = super.linux_testing_bcachefs.override {
          date = "2021-08-23";
          commit = "aed9db86aadd385b0d2591e50fde29005b41334e";
          diffHash = "0rji7k808xk7jc4yw94rjghin1ycrshri4fmiiy5y0d32fq4bb1s";
        };
        bcachefs-tools = super.bcachefs-tools.overrideAttrs (oldAttrs: rec {
          version = "unstable-2021-08-05";
          src = pkgs.fetchgit {
            url = "https://evilpiepirate.org/git/bcachefs-tools.git";
            rev = "6c42566c6204bb5dcd6af3b97257e548b9d2db67";
            sha256 = "0xagz0k3li10ydma55mnld0nb2pyfx90vsdvgjflgnx6jw3cq4dq";
          };
          postPatch = ''
            patchShebangs doc/macro2rst.py
          '';
          installFlags = oldAttrs.installFlags ++ [ "INITRAMFS_DIR=${placeholder "out"}/share/initramfs-tools" ];
          dontStrip = true;
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.python3 pkgs.python3Packages.pygments ];
        });
      }
    ) ];

    boot.supportedFilesystems = [ "bcachefs" ];

    boot.kernelPatches = [
      {
        name = "bcachefs-inline";
        patch = null;
        extraConfig = ''
          BCACHEFS_FS y
        '';
      }
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
