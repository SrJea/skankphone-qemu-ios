#!/bin/bash
# Arranca el iPod touch 1G emulado (qemu-ios). Funciona en Debian nativo y en WSL.
#   bash arrancar.sh skankphone   -> SkankPhone como shell del sistema (recomendado)
#   bash arrancar.sh springboard  -> SpringBoard parcheado con icono de SkankPhone (la app aborta: necesita ser el shell)
#   bash arrancar.sh original     -> iPhone OS 1.1 (3A101a) sin modificar
#
# Variables opcionales:
#   ITERNALIPOD=/ruta     directorio de trabajo creado por debian/instalar.sh (por defecto ~/iternalipod)
#   QEMU_DISPLAY=vnc=:1   otra salida de vídeo de QEMU (por defecto la ventana SDL)
D="${ITERNALIPOD:-$HOME/iternalipod}"
MODO=${1:-skankphone}
case "$MODO" in
  skankphone)  NAND=$D/nand_skankshell/nand ;;
  springboard) NAND=$D/nand_skank/nand ;;
  original)    NAND=$D/files/nand ;;
  *) echo "Modo desconocido: $MODO (skankphone|springboard|original)"; exit 1 ;;
esac
F=$D/files
QEMU=$D/qemu-ios/build/qemu-system-arm
[ -x "$QEMU" ] || { echo "No encuentro $QEMU. Ejecuta primero debian/instalar.sh"; exit 1; }
[ -d "$NAND" ] || { echo "No encuentro la NAND $NAND. Ejecuta primero debian/instalar.sh"; exit 1; }
pkill -f qemu-system-arm 2>/dev/null; rm -f /tmp/qemu-mon.sock /tmp/qmp.sock
echo "Arrancando modo '$MODO'... (log serie en $D/serial_$MODO.log)"
exec "$QEMU" -M iPod-Touch,bootrom=$F/bootrom_s5l8900,iboot=$F/iboot_204_n45ap.bin,nand=$NAND \
  -serial file:$D/serial_$MODO.log \
  -monitor unix:/tmp/qemu-mon.sock,server,nowait -qmp unix:/tmp/qmp.sock,server,nowait \
  ${QEMU_DISPLAY:+-display $QEMU_DISPLAY} \
  -cpu max -m 1G -pflash $F/nor_n45ap.bin
