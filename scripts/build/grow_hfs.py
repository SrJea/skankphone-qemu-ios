"""Amplía un volumen HFS+/HFSX en una imagen en bruto sin tocar el archivo de asignación
(solo si el bitmap existente ya cubre el nuevo número de bloques)."""
import struct, sys, os
src, dst, new_total = sys.argv[1], sys.argv[2], int(sys.argv[3])
data = bytearray(open(src, 'rb').read())
vh = data[1024:1536]
bs, total, free = struct.unpack('>III', vh[0x28:0x34])
alloc_logical = struct.unpack('>Q', vh[0x70:0x78])[0]
alloc_ext = [struct.unpack('>II', vh[0x80+8*i:0x88+8*i]) for i in range(8)]
print(f'blocksize={bs} total={total} free={free} bitmap_bits={alloc_logical*8} extents={alloc_ext[:2]}')
assert len(data) == total * bs, 'la imagen no mide total*blocksize'
assert new_total <= alloc_logical * 8, 'el bitmap no cubre tantos bloques'
assert new_total > total
# leer el bitmap (asumimos una sola extensión, se comprueba)
assert all(e == (0, 0) for e in alloc_ext[1:])
bstart, bcount = alloc_ext[0]
bm_off = bstart * bs
def getbit(b): return (data[bm_off + b // 8] >> (7 - b % 8)) & 1
def setbit(b, v):
    i = bm_off + b // 8; m = 1 << (7 - b % 8)
    data[i] = (data[i] | m) if v else (data[i] & ~m)
# los bits más allá del final deben estar a 0
assert not any(getbit(b) for b in range(total, new_total)), 'bits usados más allá del final'
print('último bloque viejo asignado:', getbit(total - 1))
old_last = total - 1
# ampliar la imagen
data.extend(b'\0' * ((new_total - total) * bs))
setbit(old_last, 0)          # el bloque de la cabecera alternativa antigua queda libre
setbit(new_total - 1, 1)     # el nuevo último bloque (cabecera alternativa) queda ocupado
new_free = free + (new_total - total)
struct.pack_into('>II', data, 1024 + 0x2C, new_total, new_free)
# borrar la cabecera alternativa vieja y escribir la nueva
data[total * bs - 1024: total * bs - 512] = b'\0' * 512
data[new_total * bs - 1024: new_total * bs - 512] = data[1024:1536]
open(dst, 'wb').write(data)
print(f'nuevo total={new_total} libres={new_free} ({new_free*bs/1e6:.1f} MB) -> {dst}')
