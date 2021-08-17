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
          date = "2021-08-17";
          commit = "60115eb5cf5c662f3c9d4a0048ac942d35ce7075";
          diffHash = "1xd9cngw4sdi34g4mm8v8044d5gz5bx8ja3s5g6brkcarhmiwa49";
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
