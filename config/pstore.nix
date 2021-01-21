{ pkgs, ... }:
{
  systemd.services.systemd-pstore.wantedBy = [ "sysinit.target" ];
  systemd.services."mount-pstore" = {
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.utillinux}/bin/mount -t pstore -o nosuid,noexec,nodev pstore /sys/fs/pstore";
            RemainAfterExit = true;
          };
          unitConfig = {
            DefaultDependencies = false; # prevents ordering cycle via sysinit.target
            ConditionPathIsDirectory = "/sys/fs/pstore";
          };
          after = [ "systemd-modules-load.service" ];
          wantedBy = [ "systemd-pstore.service" ];
          before = [ "systemd-pstore.service" ];
        };
}
