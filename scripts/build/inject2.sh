#!/bin/bash
set -e
pkill -f qemu-system-arm || true
H=~/iternalipod/tools/qemu-ios-generate-nand/xpwn/compile/hfs/hfsplus
P=~/iternalipod/skank/prototype-fw
ST=~/iternalipod/staging
# plist N45AP modificado (mismo formato que el original)
head -c 8 /tmp/sb/N45AP.plist | od -c | head -1
python3 - <<'PY'
import plistlib
raw=open('/tmp/sb/N45AP.plist','rb').read()
fmt = plistlib.FMT_BINARY if raw.startswith(b'bplist') else plistlib.FMT_XML
p=plistlib.loads(raw)
p['displayOrder']['iconList'].append({'displayIdentifier':'com.apple.SkankPhone'})
open('/root/iternalipod/staging/N45AP.plist','wb').write(plistlib.dumps(p, fmt=fmt))
print('formato', fmt, '->', [d['displayIdentifier'] for d in p['displayOrder']['iconList']])
PY
cd ~/iternalipod/files
cp rootfs-grown.img rootfs-skank.img
I=rootfs-skank.img
$H $I mkdir /AppleInternal
$H $I mkdir /AppleInternal/Applications
$H $I mkdir /AppleInternal/Applications/SkankPhone.app
$H $I addall $ST/SkankPhone.app /AppleInternal/Applications/SkankPhone.app > /dev/null
$H $I mkdir /System/Library/PrivateFrameworks/CHUD.framework
$H $I addall $ST/pf/CHUD.framework /System/Library/PrivateFrameworks/CHUD.framework > /dev/null
$H $I rm /System/Library/CoreServices/SpringBoard.app/N45AP.plist
$H $I add $ST/N45AP.plist /System/Library/CoreServices/SpringBoard.app/N45AP.plist
$H $I chmod 644 /System/Library/CoreServices/SpringBoard.app/N45AP.plist
for b in /AppleInternal/Applications/SkankPhone.app/SkankPhone \
  /AppleInternal/Applications/SkankPhone.app/SkankKit.framework/SkankKit \
  /System/Library/PrivateFrameworks/CHUD.framework/Versions/A/CHUD \
  /System/Library/PrivateFrameworks/CHUD.framework/Versions/A/Frameworks/CHUDCore.framework/Versions/A/CHUDCore \
  /System/Library/PrivateFrameworks/CHUD.framework/Versions/A/Frameworks/CHUDvmutils.framework/Versions/A/CHUDvmutils \
  /System/Library/PrivateFrameworks/CHUD.framework/Versions/A/Frameworks/CHUDSymbolication.framework/Versions/A/CHUDSymbolication \
  /System/Library/PrivateFrameworks/CHUD.framework/Versions/A/Frameworks/CHUDApp.framework/Versions/A/CHUDApp; do
  $H $I chmod 755 "$b" > /dev/null
done
$H $I ls /AppleInternal/Applications/SkankPhone.app | grep -E "SkankPhone$|SkankKit|Info"
$H $I ls /System/Library/CoreServices/SpringBoard.app | grep N45AP
fsck.hfsplus -n -f $I 2>&1 | grep -v "Incorrect folder count\|It should be\|HasFolderCount" | tail -4
W=~/iternalipod/nand_skank; rm -rf $W; mkdir -p $W && cd $W
cp ~/iternalipod/files/rootfs-skank.img filesystem-readonly.img
~/iternalipod/tools/qemu-ios-generate-nand/generate_nand > gen.log 2>&1; echo GEN=$?
rm filesystem-readonly.img
