{ pkgs, lib, config, ...}:
let
  unstable = import (builtins.fetchTarball "https://github.com/luc65r/nixpkgs/archive/staging.tar.gz") { config = config.nixpkgs.config; };
  kernel = {
    date = "2020-12-20";
    commit = "0b96cd54d25c8676c400ec3ac96d4c0035d34c56";
    diffhash = "";
    version = "5.10.0";
    base = "";
  };
  tools = {
    date = "2020-12-20";
    commit = "80846e9c28e76774daf7d2d46115d73f108b98db";
    hash = "0dakvlmnn85b8qfzygr7hg2xynf6vk58616vsm7brjy4jr0l4vmc";
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
              sha256 = "1fmddr393h4wrv0dq44wqc9dpnb8ikxs1avxkgmhb1mkhvadmi42";
            };
          };
          modDirVersionArg = builtins.replaceStrings ["-"] [".0-"] kernel.version;
        /*linux_testing_bcachefs = unstable."${upstreamkernel}".override {
          version = "${kernel.version}.${lib.replaceStrings ["-"] ["."] kernel.date}";
          kernelPatches = unstable."${upstreamkernel}".kernelPatches ++ [(rec {
            name = "bcachefs-${kernel.date}";
            patch = super.fetchurl {
              name = "bcachefs-${kernel.commit}.diff";
              url = "https://github.com/koverstreet/bcachefs/compare/${kernel.base}...${kernel.commit}.diff";
              sha256 = kernel.diffhash;
            };
          })];*/
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

