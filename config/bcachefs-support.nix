
{ pkgs, ...}:
let
  unstable = import <nixos-unstable/nixpkgs> {};
  fetchimport = args: ((import <nixos/nixpkgs> {config={};}).fetchurl args).outPath;
  kernel = unstable.linux_testing_bcachefs.override { argsOverride = {
    version = "4.20.2019.03.28";
    modDirVersion = "4.20.0";
    src = pkgs.fetchgit {
      url = "https://evilpiepirate.org/git/bcachefs.git";
      rev = "4d5809b6c2732840774454dc32d850bc90c81200";
      sha256 = "1ilfvbsfm28v42ygf4s2c2z6hnznhajbgz88in02jgas6v15x96a";
    };
    features.debug = true;
  }; };
  kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor kernel);  
  tools = unstable.bcachefs-tools.overrideAttrs (oldAttrs: rec {
    name = "${oldAttrs.pname}-${version}";
    src = pkgs.fetchgit {
      url = "https://evilpiepirate.org/git/bcachefs-tools.git";
      rev = "133dfeb64843af65a018be770eb005363ca59bd9";
      sha256 = "1hqmhqrz8a2gqg9rkx22vz4rcjjcaa01bhwx4nafxf768634wbgh";
    };
    version = "2019-03-28";
  });
in
  {
    disabledModules = [
      "tasks/filesystems/bcachefs.nix"
      "security/pam.nix"
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
