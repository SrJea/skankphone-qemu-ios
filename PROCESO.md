# SkankPhone en iPod touch 1G emulado (qemu-ios): registro del proceso

**Resultado: ✅ SkankPhone (prototipo 1A420, marzo 2007) arranca y funciona en el emulador.**
Hace de shell del sistema (como en los prototipos de Apple), muestra su menú principal y responde al táctil.
Por ejemplo, ejecuta sus tests: `OPControlBattery` → Passed y `OPControlWifi` → Failed (el emulador no tiene WiFi).

![SkankPhone](capturas/10_lanzador_final.png)

## Cómo usarlo

**Lo más cómodo: `Panel iPod.exe`** (panel de control compilado, 14 KB, sin instalación):

| Botón | Atajo | Qué hace |
|---|---|---|
| ⟳ Reinicio rápido | F5 | Apaga QEMU y lo vuelve a lanzar en el modo elegido (~19 s hasta SkankPhone) |
| ▶ Encender / ■ Apagar | | Arranca o cierra el emulador |
| ⌂ Home | F6 | Botón Home del iPod (tecla `H` vía QMP) |
| ⏻ Reposo | F7 | Botón de encendido/reposo (tecla `P` vía QMP) |
| 📷 Captura | F8 | Guarda la pantalla en `capturas/captura_<fecha>.png` |
| 📂 Capturas / 📄 Ver log | | Abre la carpeta de capturas o el log de la consola serie |

El desplegable elige el modo: SkankPhone (shell), iPhone OS 1.1 original o SpringBoard parcheado.
El panel solo ejecuta comandos fijos de `scripts/ctl.py` dentro de WSL; no usa red ni permisos de administrador.
Código: `panel/PanelIPod.cs`; recompilar con `panel/compilar.bat` (usa el `csc.exe` de .NET Framework 4 que trae Windows).

`scripts/ctl.py` también se puede usar a mano en WSL: `python3 ctl.py encender|reiniciar|apagar|home|power|captura|estado [modo]`.

Alternativas sin panel:

| Archivo | Qué hace |
|---|---|
| `SkankPhone.bat` | Doble clic → arranca el iPod con **SkankPhone como shell** (recomendado) |
| `iPod_original.bat` | Doble clic → iPhone OS 1.1 original con SpringBoard |
| `scripts/arrancar.sh [skankphone\|springboard\|original]` | Lo mismo desde WSL. `springboard` = SpringBoard parcheado con icono de SkankPhone |

- La pantalla se controla con el ratón en la ventana de QEMU (clic = toque).
- Log de la consola serie (syslog de iOS, útil para ver qué hace SkankPhone): `~/iternalipod/serial_<modo>.log` en WSL.
- Todo lo pesado vive en WSL Debian en `~/iternalipod/` (QEMU, imágenes, NANDs de ~556 MB cada una).

## Fuentes
- Guía SkankPhone: https://purplepro123.github.io/Purpleproject/Views/SkankPhone.html
  (pensada para dispositivo real con iPhone OS 1.1.1–1.1.5 + jailbreak ZiPhone)
- Emulador: https://github.com/devos50/qemu-ios (rama `ipod_touch_1g`)
- Guía del emulador 1G: https://devos50.github.io/blog/2022/ipod-touch-qemu-pt2/
- Generador de NAND: https://github.com/devos50/qemu-ios-generate-nand (rama `main`, trae xpwn como submódulo)

## Resumen: qué hace falta de verdad (vs. lo que dice la guía)

| La guía dice | Lo que hace falta en realidad (verificado) |
|---|---|
| Copiar **toda** `PrivateFrameworks` del volcado | Solo 5 frameworks privados: **CHUD** (+ subframeworks CHUDApp/Core/vmutils/Symbolication) y los desensambladores que CHUDApp arrastra: **ARMDisassembler, diStorm, PPCDisasm, NDISASM**. Las otras 48 bibliotecas ya están en 1.1. |
| Copiar `SkankPhone.app` a `/Applications` | Debe estar en **`/AppleInternal/Applications/SkankPhone.app`**: el binario enlaza `SkankKit` por esa ruta absoluta. |
| Abrir la app desde SpringBoard | SpringBoard 1.1 tiene una **lista blanca fija** de apps (hay que parchearla) y, aun así, SkankPhone aborta porque intenta registrar `PurpleSystemEventPort`, que ya tiene SpringBoard. **SkankPhone es un shell**: en el volcado 1A420 no existe SpringBoard y launchd lanza SkankPhone con `com.apple.SkankPhone.plist`. |

## Decisiones

| Decisión | Motivo |
|---|---|
| Arrancar primero el emulador tal cual y después inyectar SkankPhone (opción B) | Portar el emulador a otra versión de iOS implicaría otro iBoot/kernel/NOR sin garantías. Resultó que la imagen ya es 1.1 (3A101a). |
| Compilar en **WSL (Debian 13)** en vez de MSYS2 | La rama 1G solo documenta macOS/Linux. WSLg muestra la ventana SDL. |
| Editar la imagen HFS+ con `hfsplus` de **xpwn** + verificar con `fsck.hfsplus` | El kernel de WSL no trae el módulo `hfsplus` y `hdiutil` es de Mac. |
| **Ampliar** el volumen HFS+ en vez de borrar apps | Solo quedaban 4,47 MB libres. |
| Parchear 4 bytes de SpringBoard en vez de usar `sbpatcher` | `sbpatcher` (iPhone Dev Team, v1.1.1) exige un SpringBoard de 777.964 B; el de 3A101a mide 773.780 B. |
| Parchear QEMU (multitouch) | La emulación del táctil abortaba todo QEMU ante un byte desconocido. |
| SkankPhone como **LaunchDaemon** sustituyendo a SpringBoard | Es como estaba diseñado (shell del prototipo). |

## Registro paso a paso

### 1. Entorno
- Windows 11 Pro, 12 hilos. WSL2 Debian 13 (trixie), kernel 6.6.87.2, WSLg activo.
- apt: `build-essential git ninja-build pkg-config libssl-dev libsdl2-dev libpixman-1-dev libglib2.0-dev
  python3 python3-venv python3-setuptools flex bison zlib1g-dev libbz2-dev libpng-dev cmake unzip curl wget
  megatools` y más tarde `hfsprogs` (fsck HFS+) y `python3-capstone` (desensamblador).

### 2. Descargas
- `git clone --depth 1 -b ipod_touch_1g https://github.com/devos50/qemu-ios.git`
- Release `n45ap_v1` de qemu-ios: `bootrom_s5l8900`, `iboot_204_n45ap.bin`, `nor_n45ap.bin`, `nand_n45ap.zip`
- Release `it1g_nand_filesystem` del generador: `filesystem-writable.dmg` (272 MB, ya parcheado para emulación)
- `qemu-ios-generate-nand` (rama `main` + submódulo xpwn) y `Lekensteyn/dmg2img`
- Volcado SkankPhone con `megadl` (MEGA) → `1A420.tar.bz2` (105 MB)

### 3. Análisis del volcado
- `prototype-fw/` → `SystemVersion.plist`: **ProductVersion 1.0, build 1A420** (prototipo de marzo de 2007).
  Trae 3 kernels de desarrollo (`mach.development.s5l8900xrb`, `...s5l8900xfpga`, `...s5i3000smdk`).
  **No tiene SpringBoard**; sus LaunchDaemons incluyen `com.apple.SkankPhone.plist`, `PurpleTestr`, `PurpleToppr`,
  `ScreenShotr`, `telnet`, `shell`, etc.
- `SkankPhone.app` (968 KB): Mach-O ARMv6, **pre-UIKit** (LayerKit + GraphicsServices; clase `SKApplication`),
  con su propio `SkankKit.framework`.
- Dependencias: script propio `machodeps.py` (lee `LC_LOAD_DYLIB`) y `closure.py` (cierre transitivo contra la
  imagen). Resultado final: 53 bibliotecas; faltan en 3A101a solo CHUD (+4 subframeworks) y
  ARMDisassembler, diStorm, PPCDisasm, NDISASM.

### 4. Imagen del sistema del emulador
- `filesystem-writable.dmg` = DMG **UDRW** con mapa de particiones Apple; partición 3 `Apple_HFSX`
  (bloque 72, 531336 bloques de 512 B):
  `dd if=filesystem-writable.dmg of=rootfs-orig.img bs=512 skip=72 count=531336`
- Volumen `Snowbird3A101a.N45Bundle`: **iPhone OS 1.1 (3A101a)**, HFSX (keyCompare 0xBC), bloque 4 KB,
  66417 bloques, **4,47 MB libres**.
- Línea base de `fsck.hfsplus -n`: solo 130 avisos `HasFolderCount`/`Incorrect folder count` (cosméticos, de
  haberla editado con macOS moderno). Cada modificación posterior se comprobó contra esta línea base.

### 5. Compilación de QEMU
```
cd ~/iternalipod/qemu-ios/build
../configure --enable-sdl --disable-cocoa --target-list=arm-softmmu --disable-capstone --disable-slirp \
  --extra-cflags='-I/usr/include/openssl -Wno-error=int-conversion -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration' \
  --extra-ldflags='-lcrypto' --disable-werror --enable-pie
make -j12
```

### 6. Arranque del emulador original ✅
```
./qemu-system-arm -M iPod-Touch,bootrom=bootrom_s5l8900,iboot=iboot_204_n45ap.bin,nand=nand \
  -serial file:serial.log -cpu max -m 1G -pflash nor_n45ap.bin
```
Llega a SpringBoard (`capturas/01_stock_springboard.png`).

### 7. Ampliar el volumen HFS+ (`grow_hfs.py`)
El bitmap de asignación (3 bloques = 98.304 bits) ya cubre más bloques de los usados, así que basta con:
alargar la imagen, liberar el bit del antiguo último bloque, marcar el nuevo último bloque (cabecera alternativa),
actualizar `totalBlocks`/`freeBlocks` y reescribir la cabecera alternativa. 66417 → **70513 bloques (+16 MB)**.
fsck: sin errores nuevos.

### 8. Inyección de archivos (xpwn `hfsplus`)
- xpwn crea archivos con modo 0644 → `chmod 755` a cada Mach-O.
- Los enlaces simbólicos de los frameworks (`Versions/Current`, etc.) se omiten: dyld usa las rutas reales
  `Versions/A/...`.
- Contenido final añadido:
  - `/AppleInternal/Applications/SkankPhone.app/` (completa)
  - `/System/Library/PrivateFrameworks/{CHUD,ARMDisassembler,diStorm,PPCDisasm,NDISASM}.framework/Versions/A/...`
- Verificado con `cmp` (binarios idénticos al volcado) y `fsck.hfsplus`.
- NAND: `generate_nand` con la imagen renombrada a `filesystem-readonly.img`.

### 9. Hacer visible SkankPhone en SpringBoard (ingeniería inversa)
Script `annot.py` (capstone + resolución de selectores Objective-C, `__cfstring` y `__cls_refs`):
- `-[SBIconModel loadBundlesForCurrentConfiguration]` (0x7dd6c) recorre `/Applications` (tag `SBShippingAppTag`),
  `/Widgets` y **`/AppleInternal/Applications` (tag `SBInternalAppTag`)**.
- `updateIconVisibility:` (0x85ec) lee la preferencia **`SBShowInternalApps`** (dominio `com.apple.springboard`) y
  oculta o muestra los iconos con `SBInternalAppTag`. → Se añadió `SBShowInternalApps = true` en
  `/private/var/root/Library/Preferences/com.apple.springboard.plist`.
- `_addItemsToIconList:fromPath:withTags:` (0x7d050) descarta cualquier app cuyo identificador no esté en
  `-[SBPlatformController allowedDisplayIdentifiers]` (0x77ddc). Esa lista está **fija en el binario** (para N45:
  youtube, mobiletimer, mobilecal, calculator, Preferences, mobilesafari, VideoPlayer, AudioPlayer, MobileStore,
  MobileAddressBook, DemoApp, Photos).
- **Parche** (`patch_sb.py`): en `0x7d27c` (offset de archivo `0x7c27c`) `beq 0x7d6a8` (`0x0a000109`) →
  NOP `mov r0,r0` (`0xe1a00000`). SHA1 original `41ec3a85…6106e3` → parcheado `86bd2fce…6f935772`.
- Además, `com.apple.SkankPhone` se añadió al `iconList` de `SpringBoard.app/N45AP.plist` para fijar su posición.
- Resultado: el icono aparece (`capturas/05_sb_parcheado.png`), pero al abrirla aborta (ver fallos 11–12).

### 10. SkankPhone como shell del sistema ✅
- `com.apple.SpringBoard.plist` se movió a `/System/Library/LaunchDaemons.disabled/`.
- Nuevo `/System/Library/LaunchDaemons/com.apple.SkankPhone.plist`, creado a partir del del volcado:
  `ProgramArguments=[/AppleInternal/Applications/SkankPhone.app/SkankPhone]`, `OnDemand=false`,
  `EnvironmentVariables={LK_ENABLE_MBX2D: "0"}` (igual que el SpringBoard del emulador: MBX2D no está emulado).
  Se quitó `StandardErrorPath` para que los errores salgan por la consola serie.
- Resultado: menú principal de SkankPhone (Web, Media, Network Settings, Power Settings, More Other,
  Playground, Test Tools, Operator; "S/N: ABCDEFG", "[Nine parts perspiration]"). El táctil funciona.

### 11. Parche de QEMU (`qemu-multitouch.patch`)
`hw/arm/ipod_touch_multitouch.c`: un comando SPI desconocido (p. ej. `0x00` de relleno al reiniciar el driver
táctil) ahora se ignora como transferencia de 1 byte en vez de llamar a `hw_error()`.

## Fallos y soluciones

| # | Fallo | Causa | Solución |
|---|---|---|---|
| 1 | Bucles `for` en `wsl.exe -- bash -lc '...'` recibían variables vacías (`curl: no URL specified`) | `wsl.exe` pasa el comando por el shell por defecto, que expande `$f` antes que el `bash -lc` interior | Escribir scripts `.sh` y ejecutarlos con `wsl.exe -d Debian -- bash /mnt/c/.../script.sh` |
| 2 | `bash: C:/Program Files/Git/mnt/c/...: No such file` | Git Bash convierte rutas POSIX al llamar a `wsl.exe` | `export MSYS_NO_PATHCONV=1` |
| 3 | QEMU: `passing argument 1 of 'swapLong' makes pointer from integer` (`ipod_touch_sha1.c`) e `incompatible pointer type` (`ipod_touch.c:505`) | GCC 14 convierte esos avisos en errores; `--disable-werror` no basta | `-Wno-error=int-conversion -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration` |
| 4 | `dmg2img: dmg image is corrupted!` | El DMG es UDRW (bruto), no comprimido | Recortar la partición HFSX con `dd` |
| 5 | `hfsplus ... ls <archivo>` imprime `BTree inconsistent!` | `hfs_panic` de xpwn (`btree.c:228`) al buscar algunas rutas de archivo; listar directorios funciona. Se comprobó que el comparador de claves es el correcto para HFSX (binario) | Verificar cada cambio con `fsck.hfsplus -n` y `cmp` |
| 6 | `modprobe: Module hfsplus not found` | El kernel de WSL no incluye hfsplus | Editar con xpwn (userspace) |
| 7 | Solo 4,47 MB libres en la imagen (hacían falta ~6 MB) | Imagen ajustada al contenido | Ampliar el volumen (`grow_hfs.py`) |
| 8 | SkankPhone en `/Applications` no aparece en SpringBoard | Lista blanca fija `allowedDisplayIdentifiers` | Parche de SpringBoard (paso 9) |
| 9 | En `/AppleInternal/Applications` tampoco aparece | Tag `SBInternalAppTag` oculto por defecto **y** lista blanca | `SBShowInternalApps=true` + parche |
| 10 | `sbpatcher` no sirve | Espera el SpringBoard de iPhone 1.1.1 (777.964 B), no el de 3A101a (773.780 B) | Parche manual de 4 bytes equivalente |
| 11 | `dyld: Library not loaded: .../NDISASM.framework/...` (Referenced from CHUDApp) → `exited abnormally (5)` | Solo se habían revisado las dependencias directas de CHUD | Cierre transitivo (`closure.py`) → añadir ARMDisassembler, diStorm, PPCDisasm, NDISASM |
| 12 | `ABORT: Unable to register "PurpleSystemEventPort" port` → `exited abnormally (6)` | SkankPhone está hecho para ser el shell del sistema y ese puerto ya lo tiene SpringBoard | Arrancar SkankPhone con launchd en lugar de SpringBoard (paso 10) |
| 13 | `qemu: hardware error: Unknown command 0x00!` → QEMU aborta (código 134) | Emulación incompleta del táctil SPI en qemu-ios | `qemu-multitouch.patch` |
| 14 | El `printf` del parche no compilaba (`missing terminating " character`) | El `\n` se convirtió en un salto de línea real al pasar por varias capas de shell | Corregido con un script Python (`chr(92)`) |
| 15 | Fechas de archivos añadidos con xpwn salen como `8/24/2026` (hoy es 24/09) | Desfase de mes en xpwn | Cosmético, sin efecto |
| 16 | Reinicio en caliente con QMP `system_reset`: el iPod se queda colgado en `iBoot start` (>150 s) | Los periféricos de qemu-ios (NAND, PMU, LCD…) no implementan el reset | "Reinicio rápido" = apagar QEMU (`quit` por QMP, `pkill -9` si no responde) y relanzarlo; el arranque completo hasta SkankPhone tarda ~7 s |
| 17 | QEMU lanzado desde una llamada `wsl.exe` que termina podría morir con ella | Ciclo de vida de la sesión de WSL | Lanzarlo con `setsid` (verificado: sigue vivo tras cerrarse la sesión) |
| 18 | Instalador de Debian: se paraba en silencio al copiar SkankPhone | Con `set -e`, una función cuyo bucle acababa en `es_macho && chmod` devolvía 1 si el último archivo no era Mach-O | `if … then … fi` + `return 0`, y un `trap ERR` que indica la línea del fallo |
| 19 | Instalador de Debian: fsck con `Incorrect number of thread records` e `Invalid directory item count` | El `mkdir` de xpwn no comprueba si el directorio existe: hacer `mkdir /System` o `/System/Library` sobre directorios existentes duplica registros del catálogo | Crear solo los directorios nuevos; el instalador ahora **se detiene** si fsck encuentra errores que no sean los avisos cosméticos de la línea base |

## Limitaciones conocidas
- Sin red/WiFi en el emulador → Web, Ping, iPerf, tests de WiFi fallan (`Apple80211GetIfListCopy failed, error: -4`).
- Sin GPU (`LayerKit: OpenGLES can't init: 0x3003`) ni audio (`FMPlaybackMakeProcPtrs failed with err 1102`).
- SkankPhone busca `/AppleInternal/Diags/purpleskank/config.plist` (no está en el volcado); usa valores por defecto.
- Modo `springboard`: el icono aparece pero la app aborta (fallo 12). Solo es útil para comparar.

## Archivos
- `GUIA_DEBIAN.md` + `debian/instalar.sh` + `debian/accesos.sh`: instalación y uso en Debian nativo
- `Panel iPod.exe` + `panel/` (código C# y `compilar.bat`) + `scripts/ctl.py`: panel de control
- `capturas/`: capturas de cada fase (vía `screendump` del monitor QEMU → PNG con `shot.py`)
- `qemu-multitouch.patch`: parche de QEMU
- `scripts/arrancar.sh` + `.bat`: lanzadores
- `scripts/build/`: todos los scripts usados (descargas, compilación, inyección, parche SpringBoard, análisis Mach-O,
  capturas `shot.py`, toques por QMP `tap.py`)
