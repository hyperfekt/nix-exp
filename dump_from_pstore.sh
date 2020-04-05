#!/usr/bin/env bash
MOUNTPOINT=/sys/fs/pstore
mount -t pstore - $MOUNTPOINT
LAST=$(ls $MOUNTPOINT/* | head -1)
cat $(ls -r ${LAST::-5}*${LAST:-3})
