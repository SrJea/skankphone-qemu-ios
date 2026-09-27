# Guía: SkankPhone en Debian

Cómo instalar y usar el iPod touch 1G emulado con SkankPhone en un **Debian nativo** (sin Windows ni WSL).
Para la versión de Windows + WSL, ver el [README](README.md) y el panel `Panel iPod.exe`.

## Índice
1. [Requisitos](#1-requisitos)
2. [Instalación](#2-instalación)
3. [Arrancar el emulador](#3-arrancar-el-emulador)
4. [Usar el iPod](#4-usar-el-ipod)
5. [Reinicio rápido y control](#5-reinicio-rápido-y-control)
6. [Accesos directos en el escritorio](#6-accesos-directos-en-el-escritorio)
7. [Sin pantalla (servidor / SSH)](#7-sin-pantalla-servidor--ssh)
8. [Solución de problemas](#8-solución-de-problemas)
9. [Actualizar, reconstruir y desinstalar](#9-actualizar-reconstruir-y-desinstalar)

---

## 1. Requisitos

| | |
|---|---|
| Sistema | Debian 12 (bookworm) o 13 (trixie), **amd64**. Probado en Debian 13 (instalación completa desde cero dentro de WSL). Ubuntu 22.04+ debería funcionar igual, pero no está probado |
| Escritorio | Cualquier sesión gráfica (X11 o Wayland) para ver la ventana del iPod. Sin escritorio, ver [sección 7](#7-sin-pantalla-servidor--ssh) |
| Disco | ~3 GB libres en tu carpeta personal |
| RAM | 2 GB libres (el iPod emulado usa 1 GB) |
| Permisos | `sudo` para instalar paquetes (solo en el primer paso) |
| Red | ~700 MB de descargas la primera vez |

## 2. Instalación

### 2.1. Clonar el repositorio

El repositorio es privado: necesitas acceso a la cuenta de GitHub y estar autenticado.

```bash
sudo apt install -y git gh
```

```bash
gh auth login
```

```bash
gh repo clone SrJea/skankphone-qemu-ios ~/skankphone-qemu-ios
```

### 2.2. Ejecutar el instalador

```bash
bash ~/skankphone-qemu-ios/debian/instalar.sh
```

Tarda entre 5 y 15 minutos (sobre todo compilar QEMU). Hace esto:

| Paso | Qué hace |
|---|---|
| 1/5 Dependencias | Instala con `apt` lo que falte: compiladores, SDL2, glib, pixman, OpenSSL, `megatools`, `hfsprogs`… |
| 2/5 Descargas | qemu-ios (rama `ipod_touch_1g`), bootrom/iBoot/NOR/NAND del iPod touch 1G, el sistema de archivos de iPhone OS 1.1 y el volcado 1A420 con SkankPhone (MEGA) |
| 3/5 Compilación | QEMU con el parche del táctil (`qemu-multitouch.patch`), `generate_nand` y `hfsplus` (xpwn) |
| 4/5 Imágenes | Extrae la partición HFS+, la amplía 16 MB, copia SkankPhone + CHUD + 4 frameworks, parchea SpringBoard y crea la variante con SkankPhone como shell. Cada imagen se verifica con `fsck.hfsplus` |
| 5/5 NAND | Genera las NAND que usa el emulador |

Todo se guarda en `~/iternalipod/`. Para usar otra carpeta, pon delante `ITERNALIPOD=/otra/ruta`
(y úsala también al arrancar):

```bash
ITERNALIPOD=/datos/ipod bash ~/skankphone-qemu-ios/debian/instalar.sh
```

El instalador **se puede volver a ejecutar** sin problema: se salta lo que ya está hecho
(descargas, compilación) y vuelve a construir las imágenes y las NAND.

Al terminar verás algo así:

```
==> Listo
    Arrancar SkankPhone:      bash …/scripts/arrancar.sh skankphone
```

## 3. Arrancar el emulador

```bash
bash ~/skankphone-qemu-ios/scripts/arrancar.sh skankphone
```

Se abre una ventana de 320×480 con el iPod. En unos **7 segundos** aparece el menú de SkankPhone.
Cerrar la ventana apaga el emulador.

Hay tres modos:

| Modo | Qué arranca |
|---|---|
| `skankphone` | **SkankPhone como shell del sistema** (recomendado). Así funcionaba en el prototipo 1A420 |
| `original` | iPhone OS 1.1 (3A101a) sin tocar, con su SpringBoard |
| `springboard` | SpringBoard parcheado con el icono de SkankPhone. Al abrirla se cierra (necesita ser el shell); solo sirve para comparar |

Para arrancarlo en segundo plano y dejar libre la terminal:

```bash
python3 ~/skankphone-qemu-ios/scripts/ctl.py encender skankphone
```

## 4. Usar el iPod

| Acción | Cómo |
|---|---|
| Tocar la pantalla | Clic con el ratón en la ventana |
| Deslizar | Arrastrar con el botón pulsado |
| Botón **Home** | Tecla `H` con la ventana enfocada, o `ctl.py home` |
| Botón de **encendido/reposo** | Tecla `P`, o `ctl.py power` |
| Soltar el ratón de la ventana | `Ctrl` + `Alt` + `G` (si QEMU lo ha capturado) |

Menú principal de SkankPhone: **Web** (navegador con los marcadores de 2007), **Media**, **Network Settings**,
**Power Settings**, **More Other**, **Playground**, **Test Tools** (tests de hardware) y **Operator**.

Limitaciones del emulador: no hay WiFi/red (Web, Ping e iPerf fallan), ni audio, ni GPU.
El test de batería pasa y el de WiFi falla, como es de esperar.

## 5. Reinicio rápido y control

Con el emulador en marcha, desde cualquier terminal:

```bash
python3 ~/skankphone-qemu-ios/scripts/ctl.py reiniciar skankphone
```

| Comando `ctl.py` | Qué hace |
|---|---|
| `encender [modo]` | Arranca el emulador en segundo plano (modo por defecto: `skankphone`) |
| `reiniciar [modo]` | **Reinicio rápido**: apaga y vuelve a arrancar (~10 s). También sirve para cambiar de modo |
| `apagar` | Cierra el emulador |
| `home` / `power` | Pulsa los botones físicos del iPod |
| `captura` | Guarda la pantalla en `capturas/captura_<fecha>.png` dentro del repositorio |
| `estado` | Dice si está `ENCENDIDO` o `APAGADO` |

Por qué el reinicio apaga y vuelve a arrancar en vez de hacer un reset de QEMU: con `system_reset` el iPod
se queda colgado en "iBoot start" (los periféricos de qemu-ios no implementan el reset).
El arranque completo es tan rápido que no se nota.

Sugerencia: un alias en `~/.bashrc`:

```bash
alias ipod='python3 ~/skankphone-qemu-ios/scripts/ctl.py'
```

Y después: `ipod reiniciar`, `ipod home`, `ipod captura`…

## 6. Accesos directos en el escritorio

```bash
bash ~/skankphone-qemu-ios/debian/accesos.sh
```

Crea en el menú de aplicaciones (GNOME, KDE, XFCE, Cinnamon…), con el icono original de SkankPhone:

- **SkankPhone (iPod touch 1G)**: arranca el emulador
- **SkankPhone: reinicio rápido**
- **SkankPhone: apagar**
- **SkankPhone: captura**
- **SkankPhone: botón Home**
- **iPod touch 1G (iPhone OS 1.1)**: el iPod original

**Atajo de teclado global para el reinicio rápido** (GNOME): *Configuración → Teclado → Ver y personalizar
atajos → Atajos personalizados → +*, con el comando que muestra `accesos.sh` al terminar
(`env ITERNALIPOD=… python3 …/scripts/ctl.py reiniciar skankphone`) y, por ejemplo, `Super+F5`.
En KDE: *Preferencias del sistema → Atajos → Añadir comando*.

Para quitarlos:

```bash
bash ~/skankphone-qemu-ios/debian/accesos.sh --quitar
```

## 7. Sin pantalla (servidor / SSH)

Sin sesión gráfica, usa VNC:

```bash
QEMU_DISPLAY=vnc=:1 bash ~/skankphone-qemu-ios/scripts/arrancar.sh skankphone
```

Conéctate con cualquier cliente VNC a `ip-del-servidor:5901`. Por seguridad, VNC de QEMU no lleva
contraseña: si el servidor es accesible desde fuera, conéctate por un túnel SSH
(`ssh -L 5901:localhost:5901 usuario@servidor`) y usa `localhost:5901`.

Las capturas (`ctl.py captura`) funcionan igual sin pantalla.

## 8. Solución de problemas

| Problema | Solución |
|---|---|
| `No encuentro …/qemu-system-arm` o `No encuentro la NAND` | No se ha terminado la instalación, o usas otro `ITERNALIPOD` al arrancar que al instalar |
| La compilación de QEMU falla | Mira `~/iternalipod/make.log`. Con GCC 14 los errores `int-conversion` / `incompatible-pointer-types` ya están desactivados en el instalador |
| `megadl` falla o dice que se ha superado la cuota | MEGA limita la descarga gratuita. Espera un rato y vuelve a ejecutar el instalador, o descarga `1A420.tar.bz2` a mano desde la [guía original](https://purplepro123.github.io/Purpleproject/Views/SkankPhone.html) y déjalo en `~/iternalipod/skank/` |
| `SpringBoard inesperado (¿no es 3A101a?)` | El `filesystem-writable.dmg` descargado no es el esperado. Bórralo de `~/iternalipod/files/` y reinstala |
| No se abre la ventana | Comprueba que estás en una sesión gráfica (`echo $DISPLAY $WAYLAND_DISPLAY`). En Wayland sin XWayland prueba `SDL_VIDEODRIVER=wayland` delante del comando |
| La pantalla se queda en negro | Espera ~10 s. Si sigue igual, mira el log: `tail -f ~/iternalipod/serial_skankphone.log` |
| El táctil deja de responder | `ctl.py reiniciar skankphone` |
| `El emulador no está en marcha` en `ctl.py` | Arráncalo antes con `ctl.py encender` o `arrancar.sh` |
| Solo puede haber un emulador a la vez | Es a propósito: `arrancar.sh` cierra cualquier `qemu-system-arm` anterior y usa sockets fijos en `/tmp` |

El log de la consola serie (`~/iternalipod/serial_<modo>.log`) es el syslog de iOS: ahí se ve todo lo que hace
SkankPhone (tests, errores de WiFi, etc.). Para seguirlo en directo:

```bash
tail -f ~/iternalipod/serial_skankphone.log | grep SkankPhone
```

## 9. Actualizar, reconstruir y desinstalar

Actualizar el repositorio y reconstruir las imágenes (no vuelve a descargar ni a compilar QEMU):

```bash
cd ~/skankphone-qemu-ios && git pull && bash debian/instalar.sh
```

Forzar la recompilación de QEMU:

```bash
rm -rf ~/iternalipod/qemu-ios/build && bash ~/skankphone-qemu-ios/debian/instalar.sh
```

Desinstalar todo (emulador, imágenes, descargas y accesos directos):

```bash
bash ~/skankphone-qemu-ios/debian/accesos.sh --quitar
```

```bash
rm -rf ~/iternalipod ~/skankphone-qemu-ios
```

Los paquetes de `apt` se quedan instalados; si quieres quitarlos, están listados al principio de `debian/instalar.sh`.

---

Detalles técnicos de todo lo anterior (qué se parchea y por qué, los 19 fallos encontrados…): [PROCESO.md](PROCESO.md).
