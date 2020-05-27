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
            version = "5.6.2020.05.24";
            src = pkgs.fetchFromGitHub {
              owner = "koverstreet";
              repo = "bcachefs";
              rev = "2d63be71cfef677d615783e71c24d5939496b254";
              sha256 = "0m3i5q6cww7ffsbfss29np0968ik5ilmmlk7jy3sh63iifmz9rdw";
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
          version = "2020-05-25";
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs-tools";
            rev = "90d54b388666b258c97be6a4e632824d136356c4";
            sha256 = "1lnd06z7b8qy5ys4xiy2ggvnwgnwfz0c6s45llajc56f48f6l57q";
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
