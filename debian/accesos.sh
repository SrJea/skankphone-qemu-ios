#!/bin/bash
# Crea accesos directos en el menú de aplicaciones (GNOME, KDE, XFCE…) para controlar el emulador.
#   bash debian/accesos.sh           -> los crea
#   bash debian/accesos.sh --quitar  -> los borra
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="${ITERNALIPOD:-$HOME/iternalipod}"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICONOS="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
NOMBRES=(skankphone skankphone-reiniciar skankphone-apagar skankphone-captura skankphone-home ipod-original)

if [ "${1:-}" = "--quitar" ]; then
    for n in "${NOMBRES[@]}"; do rm -f "$APPS/$n.desktop"; done
    rm -f "$ICONOS/skankphone.png"
    echo "Accesos directos borrados."; exit 0
fi

mkdir -p "$APPS" "$ICONOS"
ICONO="$D/skank/prototype-fw/AppleInternal/Applications/SkankPhone.app/icon.png"
if [ -f "$ICONO" ]; then cp "$ICONO" "$ICONOS/skankphone.png"; ICONO="$ICONOS/skankphone.png"; else ICONO="computer"; fi

# ITERNALIPOD se pasa explícitamente por si no es el directorio por defecto
CTL="env ITERNALIPOD=$D python3 $REPO/scripts/ctl.py"
crear() {  # archivo nombre comentario comando
    cat > "$APPS/$1.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$2
Comment=$3
Exec=$4
Icon=$ICONO
Terminal=false
Categories=Emulator;Game;
EOF
}
crear skankphone           "SkankPhone (iPod touch 1G)" "Arranca el iPod emulado con SkankPhone como shell" "$CTL encender skankphone"
crear skankphone-reiniciar "SkankPhone: reinicio rápido" "Apaga y vuelve a arrancar el emulador (~10 s)"   "$CTL reiniciar skankphone"
crear skankphone-apagar    "SkankPhone: apagar"         "Cierra el emulador"                                "$CTL apagar"
crear skankphone-captura   "SkankPhone: captura"        "Guarda la pantalla del iPod en capturas/"          "$CTL captura"
crear skankphone-home      "SkankPhone: botón Home"     "Pulsa el botón Home del iPod"                      "$CTL home"
crear ipod-original        "iPod touch 1G (iPhone OS 1.1)" "Arranca el iPod emulado sin modificar"          "$CTL encender original"
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null || true
echo "Accesos directos creados en $APPS:"
for n in "${NOMBRES[@]}"; do echo "  - $(grep '^Name=' "$APPS/$n.desktop" | cut -d= -f2)"; done
echo
echo "Consejo: asigna un atajo de teclado global al reinicio rápido. En GNOME:"
echo "  Configuración → Teclado → Atajos personalizados → comando:"
echo "  $CTL reiniciar skankphone"
