{ pkgs, lib, config, ...}:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  options.security.pam.services = with lib; mkOption {
    type = types.loaOf (types.submodule {
      config.text = mkDefault (mkAfter "session required pam_keyinit.so force revoke");
    });
  };

  config = {
    nixpkgs.overlays = [ (
      self: super: {
        linux_testing_bcachefs = super.linux_testing_bcachefs.override { argsOverride = {
          modDirVersion = "5.1.0";
          version = "5.1.2019.09.20";
          src = pkgs.fetchgit {
            url = "https://evilpiepirate.org/git/bcachefs.git";
            rev = "dd444a83ea042ecfbeadb90e4eb9dedf441d02a7";
            sha256 = "16w8p3rwv7283f08h59wg5q1sqmr4nrv2wnxg1c83lihb0v1x2as";
          };
        }; };
        bcachefs-tools = super.bcachefs-tools.overrideAttrs (oldAttrs: rec {
          src = pkgs.fetchgit {
            url = "https://evilpiepirate.org/git/bcachefs-tools.git";
            rev = "ceee9244dedcca3df57b76fafb772207cdfbd6ee";
            sha256 = "1c52h01fsj7p2b2iv6y4jgczgdygxlgnz7dq81y20121ijbhyamd";
          };
          version = "2019-08-29";
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
