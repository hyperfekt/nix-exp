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
            version = "5.3.2020.04.04";
            src = pkgs.fetchFromGitHub {
              owner = "koverstreet";
              repo = "bcachefs";
              rev = "a27d7265e75f6d65c2b972ce4ac27abfc153c230";
              sha256 = "0wnjl4xs7073d5ipcsplv5qpcxb7zpfqd5gqvh3mhqc5j3qn816x";
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
          version = "2020-04-04";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs-tools";
            rev = "5d6e237b728cfb7c3bf2cb1a613e64bdecbd740d";
            sha256 = "1syym9k3njb0bk2mg6832cbf6r42z6y8b6hjv7dg4gmv2h7v7l7g";
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
