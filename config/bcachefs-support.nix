{ pkgs, lib, config, ...}:
let
  unstable = import <nixos-unstable> {};
  kernel = {
    date = "2021-01-26";
    commit = "ffc900d5936ae538e34d18a6ce739d0a5a9178cf";
    diffhash = "0zn81cxn5iyrq3p0cwf6mlb1ymzjg6jdrcsf7933pra44sqr6m17";
    version = "5.10.10";
    base = "2c85ebc57b3e1817b6ce1a6b703928e113a90442";
  };
  tools = {
    date = "2021-01-27";
    commit = "19f921604d3bacf7a8b243d0548b408bd93e8827";
    hash = "0ywjxqr5apfvgwvnbaigx05yfvy5sn8wlsb79z05caz8y79bg179";
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
          argsOverride.version = "${kernel.version}.${lib.replaceStrings ["-"] ["."] kernel.date}";
          kernelPatches = unstable."${upstreamkernel}".kernelPatches ++ [(rec {
            name = "bcachefs-${kernel.date}";
            patch = super.fetchurl {
              name = "bcachefs-${kernel.commit}.diff";
              url = "https://github.com/koverstreet/bcachefs/compare/${kernel.base}...${kernel.commit}.diff";
              sha256 = kernel.diffhash;
            };
          })];
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

