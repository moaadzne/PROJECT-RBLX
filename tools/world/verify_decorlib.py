"""Verification de l'existence de ReplicatedStorage.Assets._DecorLib dans un .rbxl binaire.

Lecture seule : n'ecrit rien, ne touche pas le .rbxl.
Usage: python3 verify_decorlib.py <chemin.rbxl>
"""
import sys, struct, zstandard, re

path = sys.argv[1]
data = open(path, 'rb').read()
dctx = zstandard.ZstdDecompressor()

print("Fichier :", path)
print("Taille  :", len(data), "octets")
print("Signature:", data[:8])

# --- 1. Lire tous les chunks zstd decompressables du fichier ---
frames = []
i = 0
while True:
    i = data.find(b'\x28\xb5\x2f\xfd', i)   # magic zstd
    if i == -1:
        break
    try:
        out = dctx.decompress(data[i:], max_output_size=200 * 1024 * 1024)
    except Exception:
        out = b''
    if out:
        frames.append((i, out))
    i += 4

print("\nChunks zstd decompresses :", len(frames))

# --- 2. Le chunk qui porte l'arborescence ReplicatedStorage ---
# On cherche la suite de noms d'un seul tenant, dans l'ordre du fichier :
# Assets -> _DecorLib -> StylizedNaturePack
CHAIN = [b'Assets', b'_DecorLib', b'StylizedNaturePack']
best = None
for off, out in frames:
    if b'_DecorLib' not in out:
        continue
    pos = out.find(b'Assets')
    if pos == -1:
        continue
    # les 3 noms doivent apparaitre dans l'ordre, avec peu d'octets entre eux
    p2 = out.find(b'_DecorLib', pos)
    p3 = out.find(b'StylizedNaturePack', p2)
    if p2 != -1 and p3 != -1 and (p3 - p2) < 64:
        best = (off, out, pos, p2, p3)
        break

if not best:
    print("\nRESULTAT : _DecorLib INTROUVABLE dans le fichier.")
    sys.exit(1)

off, out, pos, p2, p3 = best
print("\nChunk a l'offset", off, "- longueur", len(out))
print("  'Assets'           a l'index", pos)
print("  '_DecorLib'        a l'index", p2)
print("  'StylizedNaturePack' a l'index", p3)

# --- 3. Extraire la liste des enfants de _DecorLib (noms situes apres) ---
p = p2
names = []
while p < len(out) - 4 and len(names) < 400:
    ln = struct.unpack('<i', out[p:p+4])[0]
    if 0 <= ln <= 400 and p + 4 + ln <= len(out):
        cand = out[p+4:p+4+ln]
        if all(32 <= c < 127 for c in cand):
            names.append(cand.decode())
            p += 4 + ln
            continue
    p += 1

print("\nNoms du dossier Assets (lus dans l'ordre du chunk) :")
print("  ", names)

# --- 4. Contenu du pack nature ---
blob = b'\n'.join(o for _, o in frames).decode('latin-1')
print("\nVerification du contenu de StylizedNaturePack :")
ATTENDU = ['CoconutPalm', 'FanPalm', 'Rock', 'Coral', 'Seashell',
           'Pier', 'Raft', 'LightHouse', 'Hut', 'Bush', 'Grass']
for t in ATTENDU:
    n = len(re.findall(r'\b' + t, blob))
    marque = "OK " if n else "ABSENT"
    print("   %-6s %-14s %d occurrence(s)" % (marque, t, n))

print("\nRESULTAT : Assets._DecorLib EXISTE et contient StylizedNaturePack.")
