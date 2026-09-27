#!/bin/bash
# Arranca el iPod touch 1G emulado (qemu-ios) en WSL.
#   bash arrancar.sh skankphone   -> SkankPhone como shell del sistema (recomendado)
#   bash arrancar.sh springboard  -> SpringBoard parcheado con icono de SkankPhone (la app aborta: necesita ser el shell)
#   bash arrancar.sh original     -> iPhone OS 1.1 (3A101a) sin modificar
MODO=${1:-skankphone}
case "$MODO" in
  skankphone)  NAND=~/iternalipod/nand_skankshell/nand ;;
  springboard) NAND=~/iternalipod/nand_skank/nand ;;
  original)    NAND=~/iternalipod/files/nand ;;
  *) echo "Modo desconocido: $MODO (skankphone|springboard|original)"; exit 1 ;;
esac
F=~/iternalipod/files
cd ~/iternalipod/qemu-ios/build || exit 1
pkill -f qemu-system-arm 2>/dev/null; rm -f /tmp/qemu-mon.sock /tmp/qmp.sock
echo "Arrancando modo '$MODO'... (log serie en ~/iternalipod/serial_$MODO.log)"
exec ./qemu-system-arm -M iPod-Touch,bootrom=$F/bootrom_s5l8900,iboot=$F/iboot_204_n45ap.bin,nand=$NAND \
  -serial file:/root/iternalipod/serial_$MODO.log \
  -monitor unix:/tmp/qemu-mon.sock,server,nowait -qmp unix:/tmp/qmp.sock,server,nowait \
  -cpu max -m 1G -pflash $F/nor_n45ap.bin
