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
def sec_of(a):
    for s in secs:
        if s[2] <= a < s[2]+s[3]: return s
def a2o(a):
    s = sec_of(a); return s[4] + a - s[2] if s and s[4] else None
def u32(a):
    o = a2o(a); return struct.unpack('<I', d[o:o+4])[0] if o is not None else None
def cstr(a):
    o = a2o(a); return d[o:d.index(b'\0', o)].decode('latin1') if o is not None else None
def describe(v):
    s = sec_of(v)
    if not s: return ''
    sn = s[1]
    if sn == '__cfstring': return '@"%s"' % cstr(u32(v+8))
    if sn in ('__message_refs','__selector_refs'): return 'SEL ' + str(cstr(u32(v)))
    if sn == '__cls_refs': return 'CLASS ' + str(cstr(u32(v)))
    if sn in ('__cstring',): return '"%s"' % cstr(v)
    if sn in ('__nl_symbol_ptr','__la_symbol_ptr','__pointers'): return f'{sn}[{v:#x}]'
    return f'{s[0]},{sn}'
if sys.argv[2] == 'secs':
    for s in secs: print(s)
    sys.exit()
if sys.argv[2] == 'data':
    a = int(sys.argv[3],16)
    for i in range(int(sys.argv[4])):
        v = u32(a+4*i); print(f'{a+4*i:#x}: {v:#x} {describe(v) if v else ""}')
    sys.exit()
start, end = int(sys.argv[2],16), int(sys.argv[3],16)
md = Cs(CS_ARCH_ARM, CS_MODE_ARM); md.detail = False
for ins in md.disasm(d[a2o(start):a2o(end)], start):
    extra = ''
    if ins.mnemonic.startswith('ldr') and '[pc, #' in ins.op_str:
        off = int(ins.op_str.split('#')[1].rstrip(']'), 16); lit = ins.address + 8 + off
        v = u32(lit); extra = f'   ; ={v:#x} {describe(v)}'
    print(f'{ins.address:#x}: {ins.mnemonic} {ins.op_str}{extra}')
