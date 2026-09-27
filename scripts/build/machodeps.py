import struct, sys, os
def deps(path):
    d = open(path,'rb').read()
    magic = struct.unpack('<I', d[:4])[0]
    if magic == 0xcafebabe or magic == 0xbebafeca:
        n = struct.unpack('>I', d[4:8])[0]; off = struct.unpack('>I', d[8+8:8+12])[0]; d = d[off:]
        magic = struct.unpack('<I', d[:4])[0]
    if magic != 0xfeedface: return None, []
    cpu, sub, ftype, ncmds, sz, flags = struct.unpack('<6I', d[4:28])
    p = 28; out = []
    for _ in range(ncmds):
        cmd, csz = struct.unpack('<2I', d[p:p+8])
        if cmd in (0xc, 0x18|0x80000000, 0x18, 0xd):  # LOAD_DYLIB, WEAK, ID
            no = struct.unpack('<I', d[p+8:p+12])[0]
            name = d[p+no:p+csz].split(b'\0')[0].decode()
            out.append(('ID ' if cmd==0xd else '') + name)
        p += csz
    return (cpu, sub, ftype), out
for f in sys.argv[1:]:
    h, o = deps(f); print('##', f, h); [print('   ', x) for x in o]
