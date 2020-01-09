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
            version = "5.3.2020.01.09";
            src = pkgs.fetchFromGitHub {
              owner = "koverstreet";
              repo = "bcachefs";
              rev = "5a54fa0816521678e04b7b64eccaa2b94e83abd3";
              sha256 = "1wjc7amf0987l061hxw80kb42llh5mq8n4p9pa14zr438479slsh";
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
            rev = "ab2f1ec24f5307b0cf1e3c4ad19bf350d9f54d9f";
            sha256 = "10pafvaxg1lvwnqjv3a4rsi96bghbpcsgh3vhqilndi334k3b0hd";
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
