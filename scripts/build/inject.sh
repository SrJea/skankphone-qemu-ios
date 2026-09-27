#!/bin/bash
set -e
H=~/iternalipod/tools/qemu-ios-generate-nand/xpwn/compile/hfs/hfsplus
P=~/iternalipod/skank/prototype-fw
ST=~/iternalipod/staging
rm -rf $ST; mkdir -p $ST
# 1) app completa
cp -r $P/AppleInternal/Applications/SkankPhone.app $ST/SkankPhone.app
# 2) solo SkankKit para la ruta absoluta /AppleInternal/...
mkdir -p $ST/AI/SkankKit.framework && cp $P/AppleInternal/Applications/SkankPhone.app/SkankKit.framework/* $ST/AI/SkankKit.framework/
# 3) CHUD sin enlaces simbólicos (solo Versions/A real)
(cd $P/System/Library/PrivateFrameworks && find CHUD.framework/Versions/A -type f | while read f; do mkdir -p "$ST/pf/$(dirname "$f")"; cp "$f" "$ST/pf/$f"; done)
find $ST -type l | wc -l
du -sk $ST/*
cd ~/iternalipod/files
cp rootfs-grown.img rootfs-skank.img
I=rootfs-skank.img
$H $I mkdir /Applications/SkankPhone.app
$H $I addall $ST/SkankPhone.app /Applications/SkankPhone.app
$H $I mkdir /AppleInternal
$H $I mkdir /AppleInternal/Applications
$H $I mkdir /AppleInternal/Applications/SkankPhone.app
$H $I mkdir /AppleInternal/Applications/SkankPhone.app/SkankKit.framework
$H $I addall $ST/AI/SkankKit.framework /AppleInternal/Applications/SkankPhone.app/SkankKit.framework
$H $I mkdir /System/Library/PrivateFrameworks/CHUD.framework
$H $I addall $ST/pf/CHUD.framework /System/Library/PrivateFrameworks/CHUD.framework
for b in /Applications/SkankPhone.app/SkankPhone /Applications/SkankPhone.app/SkankKit.framework/SkankKit \
  /AppleInternal/Applications/SkankPhone.app/SkankKit.framework/SkankKit \
  /System/Library/PrivateFrameworks/CHUD.framework/Versions/A/CHUD \
  /System/Library/PrivateFrameworks/CHUD.framework/Versions/A/Frameworks/CHUDCore.framework/Versions/A/CHUDCore \
  /System/Library/PrivateFrameworks/CHUD.framework/Versions/A/Frameworks/CHUDvmutils.framework/Versions/A/CHUDvmutils \
  /System/Library/PrivateFrameworks/CHUD.framework/Versions/A/Frameworks/CHUDSymbolication.framework/Versions/A/CHUDSymbolication \
  /System/Library/PrivateFrameworks/CHUD.framework/Versions/A/Frameworks/CHUDApp.framework/Versions/A/CHUDApp; do
  $H $I chmod 755 "$b"
done
echo "--- verificación"
$H $I ls /Applications/SkankPhone.app
$H $I ls /System/Library/PrivateFrameworks/CHUD.framework/Versions/A/Frameworks/CHUDCore.framework/Versions/A
$H $I ls /AppleInternal/Applications/SkankPhone.app/SkankKit.framework
# comparar contenido extraído con el original
mkdir -p /tmp/vf && cd /tmp/vf && rm -rf ./* && $H ~/iternalipod/files/$I extract /Applications/SkankPhone.app/SkankPhone sp.bin && cmp sp.bin $P/AppleInternal/Applications/SkankPhone.app/SkankPhone && echo "SkankPhone binario idéntico"
$H ~/iternalipod/files/$I extract /System/Library/PrivateFrameworks/CHUD.framework/Versions/A/Frameworks/CHUDCore.framework/Versions/A/CHUDCore cc.bin && cmp cc.bin $P/System/Library/PrivateFrameworks/CHUD.framework/Versions/A/Frameworks/CHUDCore.framework/Versions/A/CHUDCore && echo "CHUDCore idéntico"
echo "--- fsck"
fsck.hfsplus -n -f ~/iternalipod/files/$I 2>&1 | grep -v "Incorrect folder count\|It should be\|HasFolderCount"
