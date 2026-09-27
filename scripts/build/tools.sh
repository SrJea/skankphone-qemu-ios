#!/bin/bash
mkdir -p ~/iternalipod/tools ~/iternalipod/skank && cd ~/iternalipod/skank
megadl 'https://mega.nz/file/zA1kQBrD#8R1W4CIOs0b2KGVfCYFKpijXRZJzCkeVowsSJpdy4n4' 2>&1 | tail -2
ls -la
cd ~/iternalipod/tools
git clone -q https://github.com/devos50/qemu-ios-generate-nand.git
git clone -q https://github.com/Lekensteyn/dmg2img.git
cd qemu-ios-generate-nand && cat .gitmodules && git submodule update --init 2>&1 | tail -2; ls
