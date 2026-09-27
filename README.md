# SkankPhone en qemu-ios (iPod touch 1G emulado)

Ejecuta **SkankPhone**, la app interna de Apple del prototipo de iPhone OS **1A420** (marzo de 2007),
dentro del emulador [qemu-ios](https://github.com/devos50/qemu-ios) (iPod touch 1G, iPhone OS 1.1 / 3A101a),
en Windows 11 con WSL (Debian) + WSLg.

![SkankPhone en el emulador](capturas/10_lanzador_final.png)

SkankPhone no es una app normal: en el prototipo hacía de **shell del sistema** (no había SpringBoard).
Aquí se lanza con launchd en lugar de SpringBoard y funciona: menú principal, táctil, navegador con los
marcadores de 2007 y sus tests internos.

## Empezar

- **Debian / Linux**: [**GUIA_DEBIAN.md**](GUIA_DEBIAN.md). Instalación en un comando: `bash debian/instalar.sh`
- **Windows + WSL**: `Panel iPod.exe` (panel con reinicio rápido) o `SkankPhone.bat`; ver [PROCESO.md](PROCESO.md)

## Contenido

| Ruta | Qué es |
|---|---|
| [`GUIA_DEBIAN.md`](GUIA_DEBIAN.md) | **Guía de uso en Debian**: instalación, arranque, controles, reinicio rápido, accesos directos, VNC, problemas |
| [`debian/instalar.sh`](debian/instalar.sh) | Instalador completo (dependencias, descargas, compilación, imágenes y NAND) |
| [`debian/accesos.sh`](debian/accesos.sh) | Accesos directos en el menú de aplicaciones de Linux |
| [`PROCESO.md`](PROCESO.md) | **Documentación completa**: cada paso, decisiones y 19 fallos con causa y solución |
| `Panel iPod.exe` · [`panel/`](panel) | Panel de control (WinForms): reinicio rápido (F5), Home, Reposo, capturas, log |
| [`scripts/ctl.py`](scripts/ctl.py) · [`scripts/arrancar.sh`](scripts/arrancar.sh) | Control y arranque del emulador (Debian o WSL) |
| [`scripts/build/`](scripts/build) | Scripts del proceso manual original (análisis Mach-O, ingeniería inversa de SpringBoard…). Para instalar, usa `debian/instalar.sh` |
| [`qemu-multitouch.patch`](qemu-multitouch.patch) | Parche de qemu-ios para que la emulación del táctil no tumbe QEMU |
| `capturas/` | Capturas de cada fase |

## Qué NO incluye este repositorio

Ningún binario de Apple: ni el volcado 1A420, ni los frameworks, ni el SpringBoard parcheado, ni bootrom/iBoot,
ni las imágenes NOR/NAND. Todo eso se descarga o genera con los scripts de `scripts/build/`
(ver `PROCESO.md`) y vive en WSL en `~/iternalipod/`.

## Requisitos

- **Debian 12/13 (amd64)** con escritorio, o **Windows 11 con WSL2** (distro `Debian`) y WSLg
- Los scripts usan rutas relativas al repositorio y `~/iternalipod` (cambiable con `ITERNALIPOD=`).
  Solo el panel de Windows (`panel/PanelIPod.cs`) tiene fijada la ruta `F:\Descargas\iternalipod`

## Créditos

- [devos50/qemu-ios](https://github.com/devos50/qemu-ios) y [qemu-ios-generate-nand](https://github.com/devos50/qemu-ios-generate-nand) (Martijn de Vos y colaboradores)
- Guía original de SkankPhone: [Purpleproject](https://purplepro123.github.io/Purpleproject/Views/SkankPhone.html) (gracias a Stonneph)
- [xpwn](https://github.com/planetbeing/xpwn) (planetbeing) y [dmg2img](https://github.com/Lekensteyn/dmg2img)
