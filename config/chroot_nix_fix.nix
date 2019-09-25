{
  nixpkgs.overlays = [ (
    self: super: {
      nix = (import <nixos-unstable> {}).nix.overrideAttrs (old: {
        patches = (old.patched or []) ++ [
          (builtins.fetchurl "https://github.com/NixOS/nix/commit/06010eaf199005a393f212023ec5e8bc97978537.diff")
        ];
      });
    }
  ) ];
}
