#!/bin/bash
set -e
cd ~/iternalipod/files
for f in bootrom_s5l8900 iboot_204_n45ap.bin nor_n45ap.bin nand_n45ap.zip; do
  curl -sSL -o "$f" "https://github.com/devos50/qemu-ios/releases/download/n45ap_v1/$f"
done
unzip -q -o nand_n45ap.zip
ls -la; ls nand | head -3; ls nand | wc -l
