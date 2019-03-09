
{ pkgs, ...}:
let
  unstable = import <nixos-unstable/nixpkgs> {};
  fetchimport = args: ((import <nixos/nixpkgs> {config={};}).fetchurl args).outPath;
  kernel = unstable.linux_testing_bcachefs.override { argsOverride = {
    version = "4.20.2019.03.04";
    modDirVersion = "4.20.0";
    src = pkgs.fetchgit {
      url = "https://evilpiepirate.org/git/bcachefs.git";
      rev = "ca1a2ff489de98e3adc2a49c49e4b26a2f7fd6d3";
      sha256 = "13b06m17n110dpxrbvsq538i0isi2ma02npczh1si1ry3jixi9m8";
    };
    features.debug = true;
  }; };
  kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor kernel);  
  tools = unstable.bcachefs-tools.overrideAttrs (oldAttrs: rec {
    name = "${oldAttrs.pname}-${version}";
    src = pkgs.fetchgit {
      url = "https://evilpiepirate.org/git/bcachefs-tools.git";
      rev = "ed0993c1e2ed8c4e75f34a31a46e1b1b6b89b6aa";
      sha256 = "0h0ba9mlzqvljxsy7dkbhv52r4gdaxrgg4781zl88fn8ysw6ra4a";
    };
    version = "2019-03-02";
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
    boot.kernelPatches = [ {
      name = "bcachefs-acl";
      patch = null;
      extraConfig = ''
        BCACHEFS_POSIX_ACL y
      '';
    } ];
  }
