{ pkgs, lib, config, ...}:
let
  unstable = import (builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/staging.tar.gz") { config = config.nixpkgs.config; };
  kernel = {
    date = "2021-01-19";
    commit = "8bb9b3ac6e4e2d1b5017645dbe87a94375a97003";
    diffhash = "";
    version = "5.10.0";
    base = "";
  };
  tools = {
    date = "2021-01-15";
    commit = "4a4a7e01d720eb41ba5572355b379368dde47f72";
    hash = "0ib5kqv1q34nba9xa87phjkv63wd1r4naf9z8bq58804qajd02h3";
  };
  upstreamkernel = "linux_${lib.versions.major kernel.version}_${lib.versions.minor kernel.version}";
in
{
  disabledModules = [ "tasks/filesystems/zfs.nix" ];

  imports = [ ./debugkernel.nix ];

  options.security.pam.services = with lib; mkOption {
    type = types.loaOf (types.submodule {
      config.text = mkDefault (mkAfter "session required pam_keyinit.so force revoke");
    });
  };

  config = {
    nix.useSandbox = false;

    nixpkgs.overlays = [ (
      self: super: {
        linux_testing_bcachefs = unstable.linux_testing.override {
          argsOverride = {
            version = "${kernel.version}.${lib.replaceStrings ["-"] ["."] kernel.date}";
            src = unstable.fetchFromGitHub {
              owner = "koverstreet";
              repo = "bcachefs";
              rev = kernel.commit;
              sha256 = "0ynhs2g093z4hmnh33drriymfq43sdibyy7mf9s89qd7p36sf7nr";
            };
          };
        /*linux_testing_bcachefs = unstable."${upstreamkernel}".override {
          version = "${kernel.version}.${lib.replaceStrings ["-"] ["."] kernel.date}";
          /*kernelPatches = unstable."${upstreamkernel}".kernelPatches ++ [(rec {
            name = "bcachefs-${kernel.date}";
            patch = super.fetchurl {
              name = "bcachefs-${kernel.commit}.diff";
              url = "https://github.com/koverstreet/bcachefs/compare/${kernel.base}...${kernel.commit}.diff";
              sha256 = kernel.diffhash;
            };
          })];*/
          modDirVersionArg = builtins.replaceStrings ["-"] [".0-"] kernel.version;
          dontStrip = true;
          extraConfig = "BCACHEFS_FS m";
        };
        bcachefs-tools = super.bcachefs-tools.overrideAttrs (oldAttrs: rec {
          version = tools.date;
          src = pkgs.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs-tools";
            rev = tools.commit;
            sha256 = tools.hash;
          };
          meta.broken = false;
          doCheck = false;
          buildInputs = oldAttrs.buildInputs ++ [ self.libudev.dev self.valgrind ];
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

