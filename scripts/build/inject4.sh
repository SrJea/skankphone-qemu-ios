#!/bin/bash
set -e
pkill -f qemu-system-arm || true
python3 /mnt/c/Users/stephan/AppData/Local/Temp/claude/F--Descargas-iternalipod/862f7e1a-59f2-4af6-bbee-4317403e8b26/scratchpad/patch_sb.py
H=~/iternalipod/tools/qemu-ios-generate-nand/xpwn/compile/hfs/hfsplus
I=~/iternalipod/files/rootfs-skank.img
SB=/System/Library/CoreServices/SpringBoard.app/SpringBoard
$H $I rm $SB
$H $I add ~/iternalipod/staging/SpringBoard.patched $SB
$H $I chmod 755 $SB
$H $I ls /System/Library/CoreServices/SpringBoard.app | grep -E " SpringBoard$"
$H $I extract $SB /tmp/sbcheck && cmp /tmp/sbcheck ~/iternalipod/staging/SpringBoard.patched && echo "SpringBoard en imagen == parcheado"
fsck.hfsplus -n -f $I 2>&1 | grep -v "Incorrect folder count\|It should be\|HasFolderCount" | tail -3
W=~/iternalipod/nand_skank; rm -rf $W; mkdir -p $W && cd $W
cp $I filesystem-readonly.img
~/iternalipod/tools/qemu-ios-generate-nand/generate_nand > gen.log 2>&1; echo GEN=$?
rm filesystem-readonly.img
