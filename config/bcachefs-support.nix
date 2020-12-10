{ pkgs, lib, config, ...}:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
  kernel = {
    date = "2020-12-10";
    commit = "a8bee7297ef7dd37ab984222f9f875406e207f22";
    diffhash = "0fbdry60v1c8pdp9xwrrnmgjl9w0chwp125qxczq2jnx51f5zjx9";
    version = "5.10-rc7";
    base = "0477e92881850d44910a7e94fc2c46f96faa131f";
  };
  tools = {
    date = "2020-12-04";
    commit = "db931a4571817d7d61be6bce306f1d42f7cd3398";
    hash = "1zl8lda6ni6rhsmsng6smrcjihy2irjf03h1m7nvkqmkhq44j80s";
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
        linux_testing_bcachefs = unstable.linux_testing.override {
	  argsOverride = {
            version = "${kernel.version}.${lib.replaceStrings ["-"] ["."] kernel.date}";
            src = unstable.fetchFromGitHub {
              owner = "koverstreet";
              repo = "bcachefs";
	      rev = kernel.commit;
              sha256 = "0v5fs24g9zj3k6400lspgbiha5adv9l0pkiv3awpz8cpqxv9l2ly";
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

