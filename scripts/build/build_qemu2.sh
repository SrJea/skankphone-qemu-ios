#!/bin/bash
cd ~/iternalipod/qemu-ios/build
../configure --enable-sdl --disable-cocoa --target-list=arm-softmmu --disable-capstone --disable-slirp \
  --extra-cflags='-I/usr/include/openssl -Wno-error=int-conversion -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration' \
  --extra-ldflags='-lcrypto' --disable-werror --enable-pie > ~/iternalipod/configure.log 2>&1
echo CONFIGURE_EXIT=$?
make -j12 > ~/iternalipod/make.log 2>&1
echo MAKE_EXIT=$?
grep -E "error:" ~/iternalipod/make.log | head -30
ls -la qemu-system-arm 2>&1
