{ pkgs ? import <nixpkgs> {}}:
pkgs.restic.overrideAttrs (old: {
  src = pkgs.fetchFromGitHub {
    owner = "restic";
    repo = "restic";
    rev = "616f9499ae05fdb90b21109c36515dd06dd1d252";
    sha256 = "07w97k2df27ghknma94pk92i7np1rzj71ssg601sy0nimgdpdwsv";
  };
  version = "0.9.6-98-g616f9499";
})
