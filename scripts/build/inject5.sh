#!/bin/bash
set -e
pkill -f qemu-system-arm || true
H=~/iternalipod/tools/qemu-ios-generate-nand/xpwn/compile/hfs/hfsplus
P=~/iternalipod/skank/prototype-fw/System/Library/PrivateFrameworks
ST=~/iternalipod/staging/pf2; rm -rf $ST; mkdir -p $ST
I=~/iternalipod/files/rootfs-skank.img
for fw in ARMDisassembler diStorm PPCDisasm NDISASM; do
  (cd $P && find $fw.framework/Versions/A -type f | while read f; do mkdir -p "$ST/$(dirname "$f")"; cp "$f" "$ST/$f"; done)
  du -sk $ST/$fw.framework
  $H $I mkdir /System/Library/PrivateFrameworks/$fw.framework
  $H $I addall $ST/$fw.framework /System/Library/PrivateFrameworks/$fw.framework > /dev/null
  $H $I chmod 755 /System/Library/PrivateFrameworks/$fw.framework/Versions/A/$fw > /dev/null
  $H $I ls /System/Library/PrivateFrameworks/$fw.framework/Versions/A | grep " $fw$"
done
$H $I ls / | tail -1
fsck.hfsplus -n -f $I 2>&1 | grep -v "Incorrect folder count\|It should be\|HasFolderCount" | tail -3
W=~/iternalipod/nand_skank; rm -rf $W; mkdir -p $W && cd $W
cp $I filesystem-readonly.img
~/iternalipod/tools/qemu-ios-generate-nand/generate_nand > gen.log 2>&1; echo GEN=$?
rm filesystem-readonly.img
