{ pkgs, lib, config, ...}:
let
  unstable = import <nixos-unstable> {};
  kernel = {
    date = "2021-05-17";
    commit = "0cd3e1d27a6252b6c0cc32f237c2b2414540e2e8";
    diffhash = "1wgrajiwzfhqriadkwql1g0prqr9wjrcysnjm2rd49fskdg621wl";
    version = "5.11";
    base = "f40ddce88593482919761f74910f42f4b84c004b";
  };
  tools = {
    date = "2021-05-17";
    commit = "2e2d5a3f7ed4f6d4e2a45011a82386ba82cd3976";
    hash = "0gqhcnqi58i1snydzi9na8s85nz0ppvjmp0nmfkd82wpwkxgk4d5";
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

