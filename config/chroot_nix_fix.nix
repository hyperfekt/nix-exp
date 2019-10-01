{
  nixpkgs.overlays = [ (
    self: super: {
      nix = (import <nixos-unstable> {}).nixUnstable.overrideAttrs (old: {
        src = super.fetchFromGitHub {
          owner = "nixos";
          repo = "nix";
          rev = "4e60c5ec657aeef7973d7383c0aaa113ea10b002";
          sha256 = "1avmni2xijqwfs5whlpik2s2bhv5v7rbvb7zld40zywcs1l5vxrn";
        };
      });
    }
  ) ];
}
