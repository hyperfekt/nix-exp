{ pkgs, lib, config, ...}:
let
  unstable = import <nixos-unstable> {};
  kernel = {
    date = "2021-04-16";
    commit = "9a33130654200bb1815376388fa5ecc57899aa05";
    diffhash = "1qfmrmkmas7h243zjrq1nja0g44pksjg3fmjl242k2fv1lddhqkk";
    version = "5.10";
    base = "2c85ebc57b3e1817b6ce1a6b703928e113a90442";
  };
  tools = {
    date = "2021-04-13";
    commit = "967c8704989f6194dc40ea884b5d0f713d4fb74c";
    hash = "1yfzvndrxqhj8nyjcbhnydg7xf3apyfgnmv3f7p78wxlfraafh0w";
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
        linux_testing_bcachefs = unstable."${upstreamkernel}".override {
          kernelPatches = unstable."${upstreamkernel}".kernelPatches ++ [(rec {
            name = "bcachefs-${kernel.date}";
            patch = super.fetchurl {
              name = "bcachefs-${kernel.commit}.diff";
              url = "https://evilpiepirate.org/git/bcachefs.git/rawdiff/?id=${kernel.commit}&id2=${kernel.base}";
              sha256 = kernel.diffhash;
            };
          })];
          dontStrip = true;
          extraConfig = "BCACHEFS_FS m";
        };
        bcachefs-tools = super.bcachefs-tools.overrideAttrs (oldAttrs: rec {
          version = tools.date;
          src = pkgs.fetchgit {
            url = "https://evilpiepirate.org/git/bcachefs-tools.git";
            rev = tools.commit;
            sha256 = tools.hash;
          };
          meta.broken = false;
          doCheck = false;
          dontStrip = true;
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

