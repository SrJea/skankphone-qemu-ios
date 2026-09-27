import struct, sys
from capstone import Cs, CS_ARCH_ARM, CS_MODE_ARM
d = open(sys.argv[1],'rb').read()
ncmds = struct.unpack('<I', d[16:20])[0]; p = 28; secs = []
for _ in range(ncmds):
    cmd, sz = struct.unpack('<II', d[p:p+8])
    if cmd == 1:
        nsect = struct.unpack('<I', d[p+48:p+52])[0]; q = p+56
        for i in range(nsect):
            sn = d[q:q+16].split(b'\0')[0].decode(); sg = d[q+16:q+32].split(b'\0')[0].decode()
            addr, size, off = struct.unpack('<III', d[q+32:q+44]); secs.append((sg, sn, addr, size, off)); q += 68
    p += sz
def a2o(a):
    for sg,sn,addr,size,off in secs:
        if addr <= a < addr+size and off: return off + a - addr
def o2a(o):
    for sg,sn,addr,size,off in secs:
        if off and off <= o < off+size: return addr + o - off
text = [s for s in secs if s[1]=='__text'][0]
cfs = [s for s in secs if s[1]=='__cfstring']
cfstr = {}
if cfs:
    sg,sn,addr,size,off = cfs[0]
    for i in range(0,size,16):
        isa,flags,ptr,ln = struct.unpack('<IIII', d[off+i:off+i+16]); o = a2o(ptr)
        if o: cfstr[addr+i] = d[o:o+ln].decode('latin1')
targets = sys.argv[2:]
md = Cs(CS_ARCH_ARM, CS_MODE_ARM)
for t in targets:
    for ca, s in cfstr.items():
        if s != t: continue
        print(f'=== CFString "{s}" @ {ca:#x}')
        needle = struct.pack('<I', ca); o = 0
        while True:
            o = d.find(needle, o+1)
            if o < 0: break
            a = o2a(o); print('  referenced from literal at', hex(a) if a else None)
            if a and text[2] <= a < text[2]+text[3]:
                start = max(text[2], a-0x180)
                code = d[a2o(start):a2o(a)]
                for ins in md.disasm(code, start):
                    print(f'    {ins.address:#x}: {ins.mnemonic} {ins.op_str}')
