{ pkgs, lib, config, ...}:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
  kernel = {
    date = "2020-08-25";
    commit = "7e04f345cc3a1b48a1885394e210068b7bf5a0c0";
    diffhash = "0b5w5gk86f02wxdapjdzg81cndxh8rvqqa5jh01p1x3alvbdv3nz";
    version = "5.8";
    base = "bcf876870b95592b52519ed4aafcf9d95999bc9c";
  };
  tools = {
    date = "2020-08-25";
    commit = "487ddeb03c574e902c5b749b4307e87e2150976a";
    hash = "1pcid7apxmbl9dyvxcqby3k489wi69k8pl596ddzmkw5gmhgvgid";
  };
  upstreamkernel = "linux_${lib.versions.major kernel.version}_${lib.versions.minor kernel.version}";
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
        linux_testing_bcachefs = unstable."${upstreamkernel}".override {
          version = "${kernel.version}.${lib.replaceStrings ["-"] ["."] kernel.date}";
          kernelPatches = unstable."${upstreamkernel}".kernelPatches ++ [(rec {
            name = "bcachefs-${kernel.date}";
            patch = super.fetchurl {
              name = "bcachefs-${kernel.commit}.diff";
              url = "https://github.com/koverstreet/bcachefs/compare/${kernel.base}...${kernel.commit}.diff";
              sha256 = kernel.diffhash;
            };
          })];
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

