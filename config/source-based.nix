{ config, ... }:

{
  nix.trustedBinaryCaches = [ "https://cache.nixos.org" ];

  nix.useSandbox = true;
}
