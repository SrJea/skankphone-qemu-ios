import socket, sys, time, zlib, struct, os
name = sys.argv[1] if len(sys.argv) > 1 else 'shot'
out_dir = '/mnt/f/Descargas/iternalipod/capturas'; os.makedirs(out_dir, exist_ok=True)
s = socket.socket(socket.AF_UNIX); s.connect('/tmp/qemu-mon.sock'); s.settimeout(3)
try: s.recv(4096)
except: pass
s.sendall(b'screendump /tmp/shot.ppm\n'); time.sleep(1.5); s.close()
d = open('/tmp/shot.ppm','rb').read()
parts = d.split(b'\n', 3); w, h = map(int, parts[1].split()); px = parts[3]
raw = b''.join(b'\0' + px[y*w*3:(y+1)*w*3] for y in range(h))
def chunk(t, b): return struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t + b) & 0xffffffff)
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')
p = f'{out_dir}/{name}.png'; open(p,'wb').write(png); print(p, w, h)
