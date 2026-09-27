#!/bin/bash
set -e
pkill -f qemu-system-arm || true
H=~/iternalipod/tools/qemu-ios-generate-nand/xpwn/compile/hfs/hfsplus
cd ~/iternalipod/files
cp rootfs-skank.img rootfs-skankshell.img
I=rootfs-skankshell.img
python3 - <<'PY'
import plistlib
p = plistlib.load(open('/root/iternalipod/skank/prototype-fw/System/Library/LaunchDaemons/com.apple.SkankPhone.plist','rb'))
p.pop('StandardErrorPath', None)
p['EnvironmentVariables'] = {'LK_ENABLE_MBX2D': '0'}
open('/root/iternalipod/staging/com.apple.SkankPhone.plist','wb').write(plistlib.dumps(p, fmt=plistlib.FMT_BINARY))
print(p)
PY
$H $I mkdir /System/Library/LaunchDaemons.disabled
$H $I mv /System/Library/LaunchDaemons/com.apple.SpringBoard.plist /System/Library/LaunchDaemons.disabled/com.apple.SpringBoard.plist
$H $I add ~/iternalipod/staging/com.apple.SkankPhone.plist /System/Library/LaunchDaemons/com.apple.SkankPhone.plist
$H $I chmod 644 /System/Library/LaunchDaemons/com.apple.SkankPhone.plist
$H $I ls /System/Library/LaunchDaemons
$H $I ls /System/Library/LaunchDaemons.disabled
fsck.hfsplus -n -f $I 2>&1 | grep -v "Incorrect folder count\|It should be\|HasFolderCount" | tail -3
W=~/iternalipod/nand_skankshell; rm -rf $W; mkdir -p $W && cd $W
cp ~/iternalipod/files/$I filesystem-readonly.img
~/iternalipod/tools/qemu-ios-generate-nand/generate_nand > gen.log 2>&1; echo GEN=$?
rm filesystem-readonly.img
