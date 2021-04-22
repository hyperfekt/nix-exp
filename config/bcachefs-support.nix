{ pkgs, lib, config, ...}:
let
  unstable = import <nixos-unstable> {};
  kernel = {
    date = "2021-04-21";
    commit = "e455e478dd8ce2731e882b18aa921a4e7b179604";
    diffhash = "1mfb11i7blqcvp9sbk5ahs95xh4n6l24hdfxyjd4nbrn6713q9fs";
    version = "5.10";
    base = "2c85ebc57b3e1817b6ce1a6b703928e113a90442";
  };
  tools = {
    date = "2021-04-19";
    commit = "ceac31bcb6992cb8b7770d2a0e91b055e5020431";
    hash = "1sa43qz1i58gbhk23fhwhq3glz7cgwx5rrvgv9vzjzls6h4nxv1n";
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

