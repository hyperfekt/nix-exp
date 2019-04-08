
{ pkgs, ...}:
let
  unstable = import <nixos-unstable/nixpkgs> {};
  fetchimport = args: ((import <nixos/nixpkgs> {config={};}).fetchurl args).outPath;
  kernel = unstable.linux_testing_bcachefs.override { argsOverride = {
    modDirVersion = "5.0.0";
    version = "5.0.2019.04.06";
    src = pkgs.fetchgit {
      url = "https://evilpiepirate.org/git/bcachefs.git";
      rev = "1f34297797b3283a173679b440f3d00316d1486a";
      sha256 = "1pbsbvhilcq81f2lc65735iscpax9s99nk5331fi1iapxcf8afiz";
    };
  }; };
  kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor kernel);
  tools = unstable.bcachefs-tools.overrideAttrs (oldAttrs: rec {
    name = "${oldAttrs.pname}-${version}";
    src = pkgs.fetchgit {
      url = "https://evilpiepirate.org/git/bcachefs-tools.git";
      rev = "3a59ff72a0b9bf3ee4cea7a886616edf5ab4f331";
      sha256 = "0rgbl56lhj4jnavf8f2nd2y3sfgk15q4zdcdlvvr7r0qi0ph8x78";
    };
    version = "2019-04-06";
  });
in
  {
    disabledModules = [
      "tasks/filesystems/bcachefs.nix"
      "security/pam.nix"
      "tasks/filesystems/zfs.nix" # see zfsonlinux/zfs#825
    ];
    imports = [
      (fetchimport {
        url = https://raw.githubusercontent.com/hyperfekt/nixpkgs/bcachefs-packageoptions/nixos/modules/tasks/filesystems/bcachefs.nix;
        sha256 = "0p6kkh99282s90xjc4zir08ngvmf1lyzv841cqmisqsfryxqjli5";
      })
      (fetchimport {
        url = https://raw.githubusercontent.com/hyperfekt/nixpkgs/2613905a32c627bb49362608b847d14a67ea1a14/nixos/modules/security/pam.nix;
        sha256 = "10dxyhs5znl2g3wsybq4h3qn5rqbyjxd3knxwc0y7flzj0jp1671";
      })
    ];

    boot.bcachefs.toolPackage = tools;
    boot.kernelPackages = pkgs.lib.mkForce kernelPackages;

    environment.systemPackages = [ tools ];
    boot.zfs.enableUnstable = true;
    boot.supportedFilesystems = [ "bcachefs" ];
    security.pam.defaults = "session required pam_keyinit.so force revoke";
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
  }
