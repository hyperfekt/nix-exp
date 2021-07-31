{ pkgs, lib, ... }:
{
  boot.kernelPatches = [ {
    name = "udf_fix-file-hole-when-file-tail-exists_1";
    patch = pkgs.fetchpatch {
      name = "udf_fix-file-hole-when-file-tail-exists_1.diff";
      url = "https://lore.kernel.org/lkml/20210109224054.5694-2-magnani@ieee.org/raw";
      sha256 = "116vbfhwr5sh9jl5s0jz366pd22y7l18s8dmm083c2v7kfcavwk3";
    };
  } {
    name = "udf_fix-file-hole-when-file-tail-exists_2";
    patch = pkgs.fetchpatch {
      name = "udf_fix-file-hole-when-file-tail-exists_2.diff";
      url = "https://lore.kernel.org/lkml/20210109224054.5694-3-magnani@ieee.org/raw";
      sha256 = "1m9kq31wg7a8h3bxxm3f241wn276cbn53g4dqvjfbwjm494mapsg";
    };
  } {
    name = "udf_better-lvid-checking-and-vla-cleanup";
    patch = pkgs.fetchpatch {
      name = "udf_better-lvid-checking-and-vla-cleanup.diff";
      url = "https://patchwork.kernel.org/series/476311/mbox/";
      sha256 = "150hgw5vgd4x4xbqik0n607m3czcjkrspaq9fcrlg3lq4z4azp7r";
    };
  } ];
}
