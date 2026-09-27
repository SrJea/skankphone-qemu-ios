#!/bin/bash
set -e
pkill -f qemu-system-arm || true
H=~/iternalipod/tools/qemu-ios-generate-nand/xpwn/compile/hfs/hfsplus
I=~/iternalipod/files/rootfs-skank.img
PF=/private/var/root/Library/Preferences/com.apple.springboard.plist
$H $I ls /private/var/root/Library/Preferences
$H $I extract $PF /tmp/sbprefs.plist > /dev/null
python3 - <<'PY'
import plistlib
raw=open('/tmp/sbprefs.plist','rb').read()
fmt = plistlib.FMT_BINARY if raw.startswith(b'bplist') else plistlib.FMT_XML
p=plistlib.loads(raw); p['SBShowInternalApps']=True
open('/root/iternalipod/staging/com.apple.springboard.plist','wb').write(plistlib.dumps(p, fmt=fmt))
print(fmt, p)
PY
$H $I rm $PF
$H $I add ~/iternalipod/staging/com.apple.springboard.plist $PF
$H $I chmod 644 $PF
$H $I ls /private/var/root/Library/Preferences
fsck.hfsplus -n -f $I 2>&1 | grep -v "Incorrect folder count\|It should be\|HasFolderCount" | tail -3
W=~/iternalipod/nand_skank; rm -rf $W; mkdir -p $W && cd $W
cp $I filesystem-readonly.img
~/iternalipod/tools/qemu-ios-generate-nand/generate_nand > gen.log 2>&1; echo GEN=$?
rm filesystem-readonly.img
