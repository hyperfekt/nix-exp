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
            version = "5.3.2020.03.30";
            src = pkgs.fetchFromGitHub {
              owner = "koverstreet";
              repo = "bcachefs";
              rev = "a897b0f199b2fb888f5885f115306759199094dd";
              sha256 = "1inllda3frdrda2hwf0wd11wnc4iixwqnw2lz8ln0rjd8apq91fw";
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
          version = "2020-03-30";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs-tools";
            rev = "c452666fb3dbda3edb5a442a187d3313d600cccc";
            sha256 = "1mis2div9snzmk43np6ai90wrcjagng4cs41szxl1aalrwb5ydn5";
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
