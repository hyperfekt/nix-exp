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
            modDirVersion = "5.6.0";
            version = "5.6.2020.05.13";
            src = pkgs.fetchFromGitHub {
              owner = "koverstreet";
              repo = "bcachefs";
              rev = "91fedfccb2e4d3941fe5ebe63930b52b9e800283";
              sha256 = "1f5mrg64pf4szmgl1f52m2w31irncjqw7cmm86dmi632mr2za1zn";
            };
          };
          kernelPatches = [
            unstable.kernelPatches.bridge_stp_helper
            unstable.kernelPatches.request_key_helper
            (rec {
              name = "mac8021_fix-authentication-with-iwlwifi-mvm";
              patch = super.fetchpatch {
                name = name + ".patch";
                url = "https://git.kernel.org/pub/scm/linux/kernel/git/netdev/net.git/patch/?id=be8c827f50a0bcd56361b31ada11dc0a3c2fd240";
                sha256 = "1driy0y38lln7s07ngnn17x717nhhqgbbj3rnljvylifvx053rj7";
              };
            })
          ];
        };
        bcachefs-tools = super.bcachefs-tools.overrideAttrs (oldAttrs: rec {
          version = "2020-05-09";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs-tools";
            rev = "024a01bf077a6f887b82fb74b7bd252a350dfa30";
            sha256 = "1x40nivvf4dd14rnsi3386c84zzm5bqv8nsl2jklxy8ajgr3mgnm";
          };
          buildInputs = oldAttrs.buildInputs ++ [ self.libudev.dev ];
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
