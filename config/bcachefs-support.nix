
{ pkgs, ...}:
let
  unstable = import <nixos-unstable/nixpkgs> {};
  fetchimport = args: ((import <nixos/nixpkgs> {config={};}).fetchurl args).outPath;
  kernel = unstable.linux_testing_bcachefs.override { argsOverride = {
    modDirVersion = "5.1.0";
    version = "5.1.2019.09.20";
    src = pkgs.fetchgit {
      url = "https://evilpiepirate.org/git/bcachefs.git";
      rev = "dd444a83ea042ecfbeadb90e4eb9dedf441d02a7";
      sha256 = "16w8p3rwv7283f08h59wg5q1sqmr4nrv2wnxg1c83lihb0v1x2as";
    };
  }; };
  kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor kernel);
  tools = unstable.bcachefs-tools.overrideAttrs (oldAttrs: rec {
    name = "${oldAttrs.pname}-${version}";
    src = pkgs.fetchgit {
      url = "https://evilpiepirate.org/git/bcachefs-tools.git";
      rev = "ceee9244dedcca3df57b76fafb772207cdfbd6ee";
      sha256 = "1c52h01fsj7p2b2iv6y4jgczgdygxlgnz7dq81y20121ijbhyamd";
    };
    version = "2019-08-29";
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
