#!/bin/bash
cd ~/iternalipod/tools/dmg2img && make -s > /tmp/dmg2img.log 2>&1; echo DMG2IMG_EXIT=$?; tail -5 /tmp/dmg2img.log
cd ~/iternalipod/tools/qemu-ios-generate-nand && gcc generate_nand.c -o generate_nand 2>&1 | tail -5; echo GEN_EXIT=$?
cd xpwn && mkdir -p compile && cd compile && cmake .. > /tmp/xpwn_cmake.log 2>&1; echo CMAKE_EXIT=$?; tail -5 /tmp/xpwn_cmake.log
make -j12 hfsplus > /tmp/xpwn_make.log 2>&1; echo XPWN_EXIT=$?; grep -iE ' error' /tmp/xpwn_make.log | head -20; ls -la hfs/hfsplus 2>&1
