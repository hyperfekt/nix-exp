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
          date = "2021-07-16";
          commit = "fafff176118396dfcc6fec8c304903dba3a9dcca";
          diffHash = "0ffqpmwl3jj6gczv366h79yj03345lfkp7c25h3gvwxvxxs7pxjk";
        };
        bcachefs-tools = super.bcachefs-tools.overrideAttrs (oldAttrs: rec {
          version = "unstable-2021-07-16";
          src = pkgs.fetchgit {
            url = "https://evilpiepirate.org/git/bcachefs-tools.git";
            rev = "646aabf327f423ab7e5d66b7982c6e9942a8897c";
            sha256 = "1571l8m5mx7b4z7jdfhhbhavq8bicxjd89an7825srrrskvc5fyq";
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
