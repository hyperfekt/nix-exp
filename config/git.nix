{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.git pkgs.gitAndTools.transcrypt ];
}
