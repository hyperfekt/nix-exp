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
        linux_testing_bcachefs = unstable.linux_testing_bcachefs.override {
          argsOverride = {
            modDirVersion = "5.3.0";
            version = "5.3.2020.01.05";
            src = pkgs.fetchFromGitHub {
              owner = "koverstreet";
              repo = "bcachefs";
              rev = "d763e8ab17ff1f5bdd9c5474ac15eb8791d31582";
              sha256 = "1dclmf2z2cw8pixah29df2xm5rcb4x7734gd57cz1ahlqvsqda57";
            };
          };
          kernelPatches = [
            unstable.kernelPatches.bridge_stp_helper
            unstable.kernelPatches.request_key_helper
            (rec {
              name = "dont-send-GEO_TX_POWER_LIMIT-command-to-FW-version-36";
              patch = super.fetchpatch {
                name = name + ".patch";
                url = "https://github.com/torvalds/linux/commit/fddbfeece9c7882cc47754c7da460fe427e3e85b.patch";
                sha256 = "15bp98gw5jr360p231dpnc3am9vw0c527apmxxzandmhn23d0mk1";
              };
            })
          ];
        };
        bcachefs-tools = super.bcachefs-tools.overrideAttrs (oldAttrs: rec {
          version = "2020-01-05";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs-tools";
            rev = "304691592738dc272f4150107b54a53ab43fc8be";
            sha256 = "0agb43bgb9dpkmdjq9dql9xi6wwh4k8rmbdscs2ijqxr4qpxyk93";
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
