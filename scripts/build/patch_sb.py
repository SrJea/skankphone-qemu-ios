import struct, hashlib
src='/tmp/sb/SpringBoard'; d=bytearray(open(src,'rb').read())
ADDR=0x7d27c; OFF=ADDR-0x1000   # __text: addr 0x53d0 <-> off 0x43d0
old=struct.unpack('<I', d[OFF:OFF+4])[0]
from capstone import Cs, CS_ARCH_ARM, CS_MODE_ARM
md=Cs(CS_ARCH_ARM, CS_MODE_ARM)
ctx=list(md.disasm(bytes(d[OFF-0x18:OFF+8]), ADDR-0x18))
for i in ctx: print(f'  {i.address:#x}: {i.mnemonic} {i.op_str}')
assert old>>24 == 0x0a, f'no es un beq: {old:#x}'
d[OFF:OFF+4]=struct.pack('<I',0xe1a00000)  # mov r0, r0 (NOP)
open('/root/iternalipod/staging/SpringBoard.patched','wb').write(d)
open('/root/iternalipod/staging/SpringBoard.original','wb').write(open(src,'rb').read())
print(f'parcheado {ADDR:#x} (off {OFF:#x}): {old:#010x} -> 0xe1a00000')
print('sha1 original', hashlib.sha1(open(src,'rb').read()).hexdigest())
print('sha1 parcheado', hashlib.sha1(d).hexdigest())
