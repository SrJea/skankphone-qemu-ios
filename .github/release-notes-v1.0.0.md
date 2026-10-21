Ejecuta **SkankPhone**, la app interna del prototipo de iPhone OS **1A420** (marzo de 2007), dentro del emulador [qemu-ios](https://github.com/devos50/qemu-ios) (iPod touch 1G, iPhone OS 1.1). Se lanza con launchd en lugar de SpringBoard: menú principal, táctil, navegador con los marcadores de 2007 y sus tests internos.

## Descargas

| Archivo | Para |
|---|---|
| `skankphone-1.0.0-debian.tar.gz` | **Debian 12/13 (amd64)** con escritorio: `tar xf skankphone-1.0.0-debian.tar.gz && cd skankphone-1.0.0 && bash debian/instalar.sh` |
| `skankphone-1.0.0-windows-wsl.zip` | **Windows 11 + WSL2 (Debian) + WSLg**: `Panel iPod.exe` (reinicio rápido con F5, Home, Reposo, capturas) o `SkankPhone.bat` |
| `SHA256SUMS` | hashes de los dos paquetes |

Guía de uso: [GUIA_DEBIAN.md](https://github.com/SrJea/skankphone-qemu-ios/blob/v1.0.0/GUIA_DEBIAN.md) · proceso completo y 19 fallos resueltos: [PROCESO.md](https://github.com/SrJea/skankphone-qemu-ios/blob/v1.0.0/PROCESO.md)

## Qué incluye

- instalador para Debian en un comando (dependencias, descarga, compilación de qemu-ios, imágenes y NAND) y accesos directos en el menú
- scripts de control y arranque (`scripts/ctl.py`, `scripts/arrancar.sh`)
- panel de control para Windows (WinForms) y su código
- parche de qemu-ios para que el táctil no tumbe QEMU
- los scripts del proceso manual original y capturas de cada fase

**No incluye ningún binario de Apple** (volcado 1A420, frameworks, bootrom/iBoot, imágenes NOR/NAND): el instalador los descarga o genera en tu equipo.

También viene preinstalado en la edición *device* de [meimeios](https://github.com/SrJea/meimeios) (menú *meimeios → Phones & tablets → SkankPhone*).

## Créditos

[devos50/qemu-ios](https://github.com/devos50/qemu-ios) y [qemu-ios-generate-nand](https://github.com/devos50/qemu-ios-generate-nand) · guía original en [Purpleproject](https://purplepro123.github.io/Purpleproject/Views/SkankPhone.html) (Stonneph) · [xpwn](https://github.com/planetbeing/xpwn) · [dmg2img](https://github.com/Lekensteyn/dmg2img)
