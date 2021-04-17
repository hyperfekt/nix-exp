{ pkgs, lib, config, ...}:
let
  unstable = import <nixos-unstable> {};
  kernel = {
    date = "2021-04-05";
    commit = "6a3927a96b2f362deccc7ee36e20e03f193a9e00";
    diffhash = "0hdn3arlcm4qybq91f4xvf52r0sbjcs42hg1gkcz1s3mpn9y44xp";
    version = "5.10";
    base = "2c85ebc57b3e1817b6ce1a6b703928e113a90442";
  };
  tools = {
    date = "2021-04-05";
    commit = "ce906d661e63d4318b9f26ec145f2ff5fddf5162";
    hash = "1fkfqrk3q6shjr8jnpf3myd79xdpc8hbs0grwdmzb3dhw65k9isi";
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

