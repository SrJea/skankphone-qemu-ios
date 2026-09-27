import socket, json, sys, time
x, y = float(sys.argv[1]), float(sys.argv[2])   # coordenadas de pantalla 320x480
hold = float(sys.argv[3]) if len(sys.argv) > 3 else 0.15
s = socket.socket(socket.AF_UNIX); s.connect('/tmp/qmp.sock'); f = s.makefile('rw')
def cmd(c):
    f.write(json.dumps(c) + '\n'); f.flush()
    while True:
        r = json.loads(f.readline())
        if 'return' in r or 'error' in r: return r
f.readline(); cmd({'execute': 'qmp_capabilities'})
ax = int(x / 320 * 32767); ay = int(y / 480 * 32767)
mv = [{'type': 'abs', 'data': {'axis': 'x', 'value': ax}}, {'type': 'abs', 'data': {'axis': 'y', 'value': ay}}]
print(cmd({'execute': 'input-send-event', 'arguments': {'events': mv}}))
print(cmd({'execute': 'input-send-event', 'arguments': {'events': mv + [{'type': 'btn', 'data': {'button': 'left', 'down': True}}]}}))
time.sleep(hold)
print(cmd({'execute': 'input-send-event', 'arguments': {'events': mv + [{'type': 'btn', 'data': {'button': 'left', 'down': False}}]}}))
