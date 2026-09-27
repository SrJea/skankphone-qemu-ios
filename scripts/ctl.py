#!/usr/bin/env python3
"""Control del emulador iPod touch 1G (qemu-ios).

Uso: ctl.py encender [modo] | reiniciar [modo] | apagar | home | power | captura | estado
     modo = skankphone (por defecto) | original | springboard
"""
import socket, json, sys, time, os, zlib, struct, subprocess, datetime

QMP = '/tmp/qmp.sock'; MON = '/tmp/qemu-mon.sock'
ARRANCAR = '/mnt/f/Descargas/iternalipod/scripts/arrancar.sh'
MODOS = ('skankphone', 'original', 'springboard')

def qmp(*commands):
    s = socket.socket(socket.AF_UNIX); s.settimeout(5); s.connect(QMP); f = s.makefile('rw')
    def send(c):
        f.write(json.dumps(c) + '\n'); f.flush()
        while True:
            r = json.loads(f.readline())
            if 'return' in r or 'error' in r: return r
    f.readline(); send({'execute': 'qmp_capabilities'})
    out = [send(c) for c in commands]; s.close(); return out

def tecla(qcode):
    # H = botón Home, P = botón de encendido (ver ipod_touch_key_event en hw/arm/ipod_touch.c)
    ev = lambda down: {'execute': 'input-send-event', 'arguments': {'events': [
        {'type': 'key', 'data': {'down': down, 'key': {'type': 'qcode', 'data': qcode}}}]}}
    qmp(ev(True)); time.sleep(0.15); qmp(ev(False))

def captura():
    out = '/mnt/f/Descargas/iternalipod/capturas'; os.makedirs(out, exist_ok=True)
    s = socket.socket(socket.AF_UNIX); s.settimeout(3); s.connect(MON)
    try: s.recv(4096)
    except OSError: pass
    s.sendall(b'screendump /tmp/shot.ppm\n'); time.sleep(1.5); s.close()
    d = open('/tmp/shot.ppm', 'rb').read(); p = d.split(b'\n', 3); w, h = map(int, p[1].split()); px = p[3]
    raw = b''.join(b'\0' + px[y*w*3:(y+1)*w*3] for y in range(h))
    ch = lambda t, b: struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t + b) & 0xffffffff)
    png = b'\x89PNG\r\n\x1a\n' + ch(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) + ch(b'IDAT', zlib.compress(raw)) + ch(b'IEND', b'')
    name = f'{out}/captura_{datetime.datetime.now():%Y%m%d_%H%M%S}.png'; open(name, 'wb').write(png)
    return name.replace('/mnt/f/', 'F:\\').replace('/', '\\')

def vivo():
    return subprocess.run(['pgrep', '-f', 'qemu-system-arm'], capture_output=True).returncode == 0

def apagar():
    if not vivo(): return
    try: qmp({'execute': 'quit'})
    except OSError: pass
    for _ in range(20):
        if not vivo(): return
        time.sleep(0.25)
    subprocess.run(['pkill', '-9', '-f', 'qemu-system-arm'])
    time.sleep(0.5)

def encender(modo):
    if modo not in MODOS: sys.exit(f'Modo desconocido: {modo}')
    # setsid: QEMU sigue vivo aunque termine la sesión de wsl.exe que lo lanzó
    subprocess.Popen(['setsid', 'bash', ARRANCAR, modo], stdin=subprocess.DEVNULL,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    for _ in range(40):
        if os.path.exists(QMP): break
        time.sleep(0.25)

cmd = sys.argv[1] if len(sys.argv) > 1 else 'estado'
modo = sys.argv[2] if len(sys.argv) > 2 else 'skankphone'
try:
    if cmd == 'encender':
        if vivo(): print('Ya está encendido.')
        else: encender(modo); print(f'Encendido ({modo}).')
    elif cmd == 'reiniciar':
        # system_reset de QEMU NO sirve: el iPod se queda colgado en "iBoot start".
        # Reinicio rápido = apagar QEMU y relanzarlo (~7 s hasta SkankPhone).
        apagar(); encender(modo); print(f'Reiniciado ({modo}).')
    elif cmd == 'apagar': apagar(); print('Apagado.')
    elif cmd == 'home': tecla('h'); print('Home pulsado.')
    elif cmd == 'power': tecla('p'); print('Encendido/reposo pulsado.')
    elif cmd == 'captura': print('Captura guardada en', captura())
    elif cmd == 'estado': print('ENCENDIDO' if vivo() else 'APAGADO')
    else: print(__doc__); sys.exit(2)
except (FileNotFoundError, ConnectionRefusedError, socket.timeout):
    print('El emulador no está en marcha.'); sys.exit(1)
