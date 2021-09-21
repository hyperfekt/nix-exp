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
        linuxKernel = lib.recursiveUpdate super.linuxKernel { kernels.linux_testing_bcachefs = super.linuxKernel.kernels.linux_testing_bcachefs.override {
          date = "2021-09-21";
          commit = "bd6ed9fb42c0aa36d1f4a21eeab45fe12e1fb792";
          diffHash = "0wml259g1z990kg3bdl1rpmlvcazdpv1fc8vm3kjxpncdp7637wp";
        }; };
        bcachefs-tools = super.bcachefs-tools.overrideAttrs (oldAttrs: rec {
          version = "unstable-2021-09-09";
          src = pkgs.fetchgit {
            url = "https://evilpiepirate.org/git/bcachefs-tools.git";
            rev = "2b8c1bb0910534e8687ea3e5abf6d8bbba758247";
            sha256 = "11k7axjgv1k36012qzsks6ll508sbmkyx52wa3ddgc6jsa0vn762";
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
