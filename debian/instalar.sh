#!/bin/bash
# Instalador completo de SkankPhone en qemu-ios (iPod touch 1G) para Debian 12/13 (amd64).
#
#   bash debian/instalar.sh
#
# Hace, en este orden (cada paso se salta si ya está hecho, así que se puede volver a ejecutar):
#   1. Instala dependencias con apt
#   2. Descarga qemu-ios, los archivos del iPod touch 1G, el sistema de archivos y el volcado 1A420
#   3. Compila qemu-ios (con el parche del táctil) y las herramientas (generate_nand, hfsplus)
#   4. Construye las imágenes del sistema (original ampliada, SpringBoard parcheado, SkankPhone como shell)
#   5. Genera las NAND para el emulador
#
# Directorio de trabajo: $ITERNALIPOD (por defecto ~/iternalipod). Ocupa unos 3 GB.
set -euo pipefail
trap 'echo -e "\n\033[31mERROR en la línea $LINENO de instalar.sh (código $?)\033[0m" >&2' ERR

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="${ITERNALIPOD:-$HOME/iternalipod}"
F="$D/files"; T="$D/tools"; W="$D/work"; Q="$D/qemu-ios"
MEGA_URL='https://mega.nz/file/zA1kQBrD#8R1W4CIOs0b2KGVfCYFKpijXRZJzCkeVowsSJpdy4n4'
REL1G='https://github.com/devos50/qemu-ios/releases/download/n45ap_v1'
RELFS='https://github.com/devos50/qemu-ios-generate-nand/releases/download/it1g_nand_filesystem'
SB_SHA1_ORIGINAL='41ec3a856b84103f4b1ecdc98aa503edbf6106e3'
NUEVO_TOTAL_BLOQUES=70513   # 66417 originales + 4096 (16 MB libres de más)

paso() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32m✓\033[0m %s\n' "$*"; }
aviso(){ printf '    \033[33m!\033[0m %s\n' "$*"; }

descargar() {  # url destino
    if [ -s "$2" ]; then ok "ya descargado: $(basename "$2")"; return; fi
    curl -fL --retry 3 --progress-bar -o "$2.part" "$1"
    mv "$2.part" "$2"; ok "descargado: $(basename "$2")"
}

mkdir -p "$F" "$T" "$W" "$D/skank"

# ---------------------------------------------------------------------------
paso "1/5 Dependencias (apt)"
PAQUETES=(build-essential git ninja-build pkg-config libssl-dev libsdl2-dev libpixman-1-dev libglib2.0-dev
          python3 python3-venv python3-setuptools flex bison zlib1g-dev libbz2-dev libpng-dev cmake unzip
          curl megatools hfsprogs)
FALTAN=()
for p in "${PAQUETES[@]}"; do dpkg -s "$p" >/dev/null 2>&1 || FALTAN+=("$p"); done
if [ ${#FALTAN[@]} -gt 0 ]; then
    SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
    $SUDO apt-get update
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "${FALTAN[@]}"
fi
ok "dependencias instaladas"

# ---------------------------------------------------------------------------
paso "2/5 Descargas"
for f in bootrom_s5l8900 iboot_204_n45ap.bin nor_n45ap.bin nand_n45ap.zip; do descargar "$REL1G/$f" "$F/$f"; done
descargar "$RELFS/filesystem-writable.dmg" "$F/filesystem-writable.dmg"
if [ ! -d "$F/nand" ]; then (cd "$F" && unzip -q nand_n45ap.zip && rm -rf __MACOSX); fi
ok "NAND original descomprimida"

if [ ! -s "$D/skank/1A420.tar.bz2" ]; then
    (cd "$D/skank" && megadl "$MEGA_URL")
fi
[ -d "$D/skank/prototype-fw" ] || tar -xjf "$D/skank/1A420.tar.bz2" -C "$D/skank"
P="$D/skank/prototype-fw"
[ -x "$P/AppleInternal/Applications/SkankPhone.app/SkankPhone" ] || { echo "No se encuentra SkankPhone en el volcado"; exit 1; }
ok "volcado 1A420 listo"

# ---------------------------------------------------------------------------
paso "3/5 Compilación"
if [ ! -d "$Q" ]; then
    git clone --depth 1 -b ipod_touch_1g https://github.com/devos50/qemu-ios.git "$Q"
fi
if git -C "$Q" apply --check "$REPO/qemu-multitouch.patch" 2>/dev/null; then
    git -C "$Q" apply "$REPO/qemu-multitouch.patch"; ok "parche del táctil aplicado"
else
    ok "parche del táctil ya estaba aplicado"
fi
if [ ! -x "$Q/build/qemu-system-arm" ] || [ "$Q/hw/arm/ipod_touch_multitouch.c" -nt "$Q/build/qemu-system-arm" ]; then
    mkdir -p "$Q/build"
    (cd "$Q/build" && [ -f build.ninja ] || ../configure --enable-sdl --disable-cocoa --target-list=arm-softmmu \
        --disable-capstone --disable-slirp --disable-werror --enable-pie \
        --extra-cflags='-I/usr/include/openssl -Wno-error=int-conversion -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration' \
        --extra-ldflags='-lcrypto' > "$D/configure.log" 2>&1)
    echo "    compilando QEMU (varios minutos; log en $D/make.log)…"
    make -C "$Q/build" -j"$(nproc)" > "$D/make.log" 2>&1 || { tail -30 "$D/make.log"; exit 1; }
fi
ok "qemu-system-arm"

G="$T/qemu-ios-generate-nand"
if [ ! -d "$G" ]; then
    git clone -b main https://github.com/devos50/qemu-ios-generate-nand.git "$G"
    git -C "$G" submodule update --init
fi
[ -x "$G/generate_nand" ] || gcc "$G/generate_nand.c" -o "$G/generate_nand"
H="$G/xpwn/compile/hfs/hfsplus"
if [ ! -x "$H" ]; then
    mkdir -p "$G/xpwn/compile"
    (cd "$G/xpwn/compile" && cmake .. > "$D/xpwn_cmake.log" 2>&1 && make -j"$(nproc)" hfsplus > "$D/xpwn_make.log" 2>&1)
fi
ok "generate_nand y hfsplus"

# ---------------------------------------------------------------------------
paso "4/5 Imágenes del sistema"
# hfsplus (xpwn) no tiene códigos de salida fiables: no abortamos aquí y validamos después con cmp/fsck
hfs() { "$H" "$IMG" "$@" > /dev/null 2>&1 || true; }
es_macho() { head -c 4 "$1" | od -An -tx1 | tr -d ' \n' | grep -qE '^(cefaedfe|cafebabe)$'; }
comprobar_fsck() {  # la imagen original ya trae avisos cosméticos de "folder count"; solo alertamos de otros
    local raros
    raros=$(fsck.hfsplus -n -f "$1" 2>&1 | grep -vE 'folder count|It should be|HasFolderCount|^\*\*|Executing fsck|volume name|case-sensitive' || true)
    if [ -n "$raros" ]; then
        aviso "fsck encuentra errores en $(basename "$1"):"; echo "$raros" | sed 's/^/      /'
        echo "    La imagen está dañada; no se genera la NAND."; exit 1
    fi
    ok "fsck limpio: $(basename "$1")"
}
anadir_dir() {  # carpeta_local ruta_en_imagen : copia todo y da permisos de ejecución a los Mach-O
    # Ojo: la ruta de destino debe crearse antes con "hfs mkdir" SOLO para directorios nuevos.
    # El mkdir de xpwn no comprueba si ya existe: sobre un directorio existente duplica registros
    # (fsck: "Incorrect number of thread records" / "Invalid directory item count").
    local src="$1" dst="$2" f
    hfs addall "$src" "$dst"
    while IFS= read -r -d '' f; do
        if es_macho "$f"; then hfs chmod 755 "$dst/${f#"$src"/}"; fi
    done < <(find "$src" -type f -print0)
    return 0
}

# 4a. Partición HFSX del DMG (UDRW con mapa de particiones Apple; dmg2img no sirve)
if [ ! -s "$W/rootfs-orig.img" ]; then
python3 - "$F/filesystem-writable.dmg" "$W/rootfs-orig.img" <<'PY'
import struct, sys
src, dst = sys.argv[1:3]
f = open(src, 'rb'); cab = f.read(4096)
for i in range(1, 8):
    e = cab[512*i:512*(i+1)]
    if e[:2] != b'PM': continue
    inicio, n = struct.unpack('>II', e[8:16]); tipo = e[48:80].split(b'\0')[0]
    if tipo in (b'Apple_HFSX', b'Apple_HFS'):
        f.seek(inicio * 512); open(dst, 'wb').write(f.read(n * 512))
        print(f'    partición {tipo.decode()} (bloque {inicio}, {n} bloques)'); break
else:
    sys.exit('No hay partición HFS en el DMG')
PY
fi
ok "rootfs-orig.img"

# 4b. Ampliar el volumen (solo quedaban 4,5 MB libres)
[ -s "$W/rootfs-grown.img" ] || python3 "$REPO/scripts/build/grow_hfs.py" "$W/rootfs-orig.img" "$W/rootfs-grown.img" "$NUEVO_TOTAL_BLOQUES" | sed 's/^/    /'
comprobar_fsck "$W/rootfs-grown.img"

# 4c. Preparar lo que se inyecta
ST="$W/staging"; rm -rf "$ST"; mkdir -p "$ST/pf" "$ST/sb"
cp -r "$P/AppleInternal/Applications/SkankPhone.app" "$ST/SkankPhone.app"
for fw in CHUD ARMDisassembler diStorm PPCDisasm NDISASM; do
    # solo archivos reales de Versions/A (dyld usa esas rutas; los enlaces simbólicos sobran)
    (cd "$P/System/Library/PrivateFrameworks" && find "$fw.framework/Versions/A" -type f | while read -r f; do
        mkdir -p "$ST/pf/$(dirname "$f")"; cp "$f" "$ST/pf/$f"; done)
done
IMG="$W/rootfs-orig.img"
hfs extract /System/Library/CoreServices/SpringBoard.app/SpringBoard "$ST/sb/SpringBoard"
hfs extract /System/Library/CoreServices/SpringBoard.app/N45AP.plist "$ST/sb/N45AP.plist"
hfs extract /private/var/root/Library/Preferences/com.apple.springboard.plist "$ST/sb/prefs.plist"

python3 - "$ST" "$P" "$SB_SHA1_ORIGINAL" <<'PY'
import hashlib, plistlib, struct, sys
st, p, sha_esperado = sys.argv[1:4]
def cargar(ruta):
    raw = open(ruta, 'rb').read()
    return plistlib.loads(raw), (plistlib.FMT_BINARY if raw.startswith(b'bplist') else plistlib.FMT_XML)
# SpringBoard: quitar la lista blanca de apps (beq en 0x7d27c -> NOP)
d = bytearray(open(f'{st}/sb/SpringBoard', 'rb').read())
assert hashlib.sha1(d).hexdigest() == sha_esperado, 'SpringBoard inesperado (¿no es 3A101a?)'
OFF = 0x7c27c
assert struct.unpack('<I', d[OFF:OFF+4])[0] == 0x0a000109
d[OFF:OFF+4] = struct.pack('<I', 0xe1a00000)
open(f'{st}/sb/SpringBoard.parcheado', 'wb').write(d)
# N45AP.plist: SkankPhone en la lista de iconos
n45, fmt = cargar(f'{st}/sb/N45AP.plist')
lista = n45['displayOrder']['iconList']
if not any(x.get('displayIdentifier') == 'com.apple.SkankPhone' for x in lista):
    lista.append({'displayIdentifier': 'com.apple.SkankPhone'})
open(f'{st}/sb/N45AP.nuevo.plist', 'wb').write(plistlib.dumps(n45, fmt=fmt))
# Preferencias de SpringBoard: mostrar apps de /AppleInternal/Applications
pr, fmt = cargar(f'{st}/sb/prefs.plist'); pr['SBShowInternalApps'] = True
open(f'{st}/sb/prefs.nuevo.plist', 'wb').write(plistlib.dumps(pr, fmt=fmt))
# LaunchDaemon de SkankPhone (del volcado) + LK_ENABLE_MBX2D=0 como el SpringBoard del emulador
ld = plistlib.load(open(f'{p}/System/Library/LaunchDaemons/com.apple.SkankPhone.plist', 'rb'))
ld.pop('StandardErrorPath', None); ld['EnvironmentVariables'] = {'LK_ENABLE_MBX2D': '0'}
open(f'{st}/com.apple.SkankPhone.plist', 'wb').write(plistlib.dumps(ld, fmt=plistlib.FMT_BINARY))
print('    SpringBoard parcheado y plists preparados')
PY

reemplazar() {  # local ruta_en_imagen modo
    hfs rm "$2"; hfs add "$1" "$2"; hfs chmod "$3" "$2"
}

# 4d. Variante "springboard": SkankPhone con icono en SpringBoard (la app aborta: necesita ser el shell)
IMG="$W/rootfs-skank.img"
cp "$W/rootfs-grown.img" "$IMG"
hfs mkdir /AppleInternal
hfs mkdir /AppleInternal/Applications
hfs mkdir /AppleInternal/Applications/SkankPhone.app
anadir_dir "$ST/SkankPhone.app" /AppleInternal/Applications/SkankPhone.app
for fw in CHUD ARMDisassembler diStorm PPCDisasm NDISASM; do
    hfs mkdir "/System/Library/PrivateFrameworks/$fw.framework"
    anadir_dir "$ST/pf/$fw.framework" "/System/Library/PrivateFrameworks/$fw.framework"
done
reemplazar "$ST/sb/SpringBoard.parcheado" /System/Library/CoreServices/SpringBoard.app/SpringBoard 755
reemplazar "$ST/sb/N45AP.nuevo.plist" /System/Library/CoreServices/SpringBoard.app/N45AP.plist 644
reemplazar "$ST/sb/prefs.nuevo.plist" /private/var/root/Library/Preferences/com.apple.springboard.plist 644
# comprobación: el binario dentro de la imagen es idéntico al del volcado
"$H" "$IMG" extract /AppleInternal/Applications/SkankPhone.app/SkankPhone "$ST/check.bin" >/dev/null 2>&1
cmp -s "$ST/check.bin" "$P/AppleInternal/Applications/SkankPhone.app/SkankPhone" || { echo "SkankPhone no se copió bien"; exit 1; }
comprobar_fsck "$IMG"

# 4e. Variante "skankphone": SkankPhone sustituye a SpringBoard como shell del sistema
IMG="$W/rootfs-skankshell.img"
cp "$W/rootfs-skank.img" "$IMG"
hfs mkdir /System/Library/LaunchDaemons.disabled
hfs mv /System/Library/LaunchDaemons/com.apple.SpringBoard.plist /System/Library/LaunchDaemons.disabled/com.apple.SpringBoard.plist
hfs add "$ST/com.apple.SkankPhone.plist" /System/Library/LaunchDaemons/com.apple.SkankPhone.plist
hfs chmod 644 /System/Library/LaunchDaemons/com.apple.SkankPhone.plist
comprobar_fsck "$IMG"

# ---------------------------------------------------------------------------
paso "5/5 NAND"
generar_nand() {  # imagen carpeta_destino
    rm -rf "$2"; mkdir -p "$2"
    cp "$1" "$2/filesystem-readonly.img"
    (cd "$2" && "$G/generate_nand" > gen.log 2>&1)
    rm "$2/filesystem-readonly.img"
    [ -d "$2/nand/bank7" ] || { echo "generate_nand falló (ver $2/gen.log)"; exit 1; }
    ok "$(basename "$2")/nand"
}
generar_nand "$W/rootfs-skank.img" "$D/nand_skank"
generar_nand "$W/rootfs-skankshell.img" "$D/nand_skankshell"
rm -rf "$ST"

paso "Listo"
cat <<EOF
    Arrancar SkankPhone:      bash $REPO/scripts/arrancar.sh skankphone
    Control (otra terminal):  python3 $REPO/scripts/ctl.py reiniciar|apagar|home|power|captura
    Accesos directos:         bash $REPO/debian/accesos.sh
EOF
