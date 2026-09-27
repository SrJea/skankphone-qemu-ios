import sys, os, subprocess
sys.argv=[sys.argv[0]]
exec(open('/mnt/c/Users/stephan/AppData/Local/Temp/claude/F--Descargas-iternalipod/862f7e1a-59f2-4af6-bbee-4317403e8b26/scratchpad/machodeps.py').read().split('for f in sys.argv')[0])
machodeps_fn=deps
DUMP='/root/iternalipod/skank/prototype-fw'
H='/root/iternalipod/tools/qemu-ios-generate-nand/xpwn/compile/hfs/hfsplus'
IMG='/root/iternalipod/files/rootfs-orig.img'
def in_image(p):
    d,b=os.path.split(p)
    out=subprocess.run([H,IMG,'ls',d],capture_output=True,text=True).stdout
    return any(l.split()[-1:]==[b] for l in out.splitlines())
seen={}; todo=['/AppleInternal/Applications/SkankPhone.app/SkankPhone']
while todo:
    p=todo.pop()
    if p in seen: continue
    local=DUMP+p
    img=in_image(p)
    seen[p]=('IMAGEN' if img else ('DUMP' if os.path.exists(local) else 'NO EXISTE'))
    if os.path.exists(local):
        _,dl=machodeps_fn(os.path.realpath(local))
        for x in dl:
            if not x.startswith('ID '): todo.append(x)
for p,s in sorted(seen.items(), key=lambda x:x[1]): print(f'{s:10} {p}')
