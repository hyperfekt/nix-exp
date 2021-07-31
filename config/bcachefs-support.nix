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
          date = "2021-07-30";
          commit = "4cbe560ebff23c89a3ed523b810ed045fb0409ed";
          diffHash = "19pl3h6mbcgpvxrg02gf73wymydpxg6395x5dhzc0qmrp22hrc6j";
        };
        bcachefs-tools = super.bcachefs-tools.overrideAttrs (oldAttrs: rec {
          version = "unstable-2021-07-28";
          src = pkgs.fetchgit {
            url = "https://evilpiepirate.org/git/bcachefs-tools.git";
            rev = "ac82bc1ea5473d1c0945b13a71c5d1d9ef692e23";
            sha256 = "032x5lhznkgkc1411hfps6k63kj2cv6savpj1pyymmf5gx9n3lla";
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
