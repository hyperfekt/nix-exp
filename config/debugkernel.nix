{ config, ... }:
{
  isoImage.storeContents = [
    config.system.build.kernel.dev
    config.system.build.kernel.drvPath
  ];

  boot.kernelPatches = [ {
    name = "debug";
    patch = null;
    extraConfig = ''
      DEBUG_KERNEL y
      DEBUG_INFO y
      DYNAMIC_DEBUG y
    '';
  } {
    name = "sanitize";
    patch = null;
    extraConfig = ''
      KASAN y
      KASAN_INLINE y
      STACKTRACE y
      UBSAN y
      UBSAN_SANITIZE_ALL y
    '';
  } {
    name = "detect_lockups";
    patch = null;
    extraConfig = ''
      LOCKUP_DETECTOR y
      SOFTLOCKUP_DETECTOR y
      HARDLOCKUP_DETECTOR y
      DETECT_HUNG_TASK y
      WQ_WATCHDOG y
    '';
  } {
    name = "debug_locks";
    patch = null;
    extraConfig = ''
      PROVE_LOCKING y
      LOCK_STAT y
    '';
  }];

  boot.kernel.sysctl."kernel.softlockup_panic" = true;
  boot.kernel.sysctl."kernel.hardlockup_panic" = true;
  boot.kernel.sysctl."kernel.hung_task_timeout_secs" = 30;
}
