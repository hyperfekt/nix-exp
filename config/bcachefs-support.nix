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
            version = "5.3.2020.01.04";
            src = pkgs.fetchFromGitHub {
              owner = "koverstreet";
              repo = "bcachefs";
              rev = "153ed7caf63c11ff1019f77cdd3d473583f254b2";
              sha256 = "17lbjwicrhk5dz8jb4zcma4b02njl64mil8qxzgix5m3nh5yh109";
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
          version = "2020-01-04";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs-tools";
            rev = "abbe66b6a5051027fd63b2a4cd4cb1d4b09410f6";
            sha256 = "1alzf3hrrds7kfww67z1gwjpilq6z0ppy01avx8w2ci39im21j7z";
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
