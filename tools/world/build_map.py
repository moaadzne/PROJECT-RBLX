#!/usr/bin/env python3
"""
build_map.py — plan de situation de l'ile, genere depuis la vraie Config.lua.

Ce n'est PAS une maquette. Toutes les coordonnees, tous les rayons et tous
les chiffres sont lus dans src/ReplicatedStorage/Shared/Config.lua, le fichier
que le serveur execute reellement. Si le code change, le plan change.

Sortie : tools/world/island_map.svg
Usage  : python3 tools/world/build_map.py
"""

import re
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "src" / "ReplicatedStorage" / "Shared" / "Config.lua"
OUT = ROOT / "tools" / "world" / "island_map.svg"

src = CONFIG.read_text(encoding="utf-8")


def block(name):
    """Extrait Config.<name> = { ... } par equilibre d'accolades."""
    i = src.index("Config.%s = {" % name)
    j = src.index("{", i)
    depth, k = 0, j
    while k < len(src):
        if src[k] == "{":
            depth += 1
        elif src[k] == "}":
            depth -= 1
            if depth == 0:
                break
        k += 1
    return src[j : k + 1]


def num(pattern, text, default=None):
    m = re.search(pattern, text)
    return float(m.group(1)) if m else default


def vec3(pattern, text):
    m = re.search(pattern, text)
    return (float(m.group(1)), float(m.group(2))) if m else (0.0, 0.0)


# ---------------------------------------------------------------- donnees
isl = block("Island")
ISLAND_SIZE = num(r"size\s*=\s*([\d.]+)", isl, 600)
SEA_MARGIN = num(r"seaMargin\s*=\s*([\d.]+)", isl, 30)
COVE = num(r"coveRadius\s*=\s*([\d.]+)", isl, 70)

wave = block("Wave")
W_H, W_T = num(r"height\s*=\s*([\d.]+)", wave, 30), num(r"thickness\s*=\s*([\d.]+)", wave, 40)

ext = block("ExtremeTide")
reef_c = vec3(r"reef\s*=\s*\{\s*center\s*=\s*Vector3\.new\(([-\d.]+),\s*[-\d.]+,\s*([-\d.]+)\)", ext)
REEF_R = num(r"radius\s*=\s*([\d.]+)", ext, 30)

rings_block = block("Rings")
RINGS = [
    dict(
        name=n,
        rmin=float(rm),
        rmax=float(rx),
        maxItems=int(mi),
        spawnEvery=float(se),
        creatures=re.findall(r'"(\w+)"', cr),
    )
    for n, rm, rx, mi, se, cr in re.findall(
        r'name\s*=\s*"([^"]+)".*?rMin\s*=\s*([\d.]+),\s*rMax\s*=\s*([\d.]+),'
        r"\s*maxItems\s*=\s*(\d+),\s*spawnEvery\s*=\s*([\d.]+),"
        r".*?creatures\s*=\s*\{(.*?)\}",
        rings_block,
        re.S,
    )
]

rar_block = block("Rarities")
COLORS = dict(
    (m[0], "#%02x%02x%02x" % (int(m[1]), int(m[2]), int(m[3])))
    for m in re.findall(
        r"(\w+)\s*=\s*\{[^}]*?color\s*=\s*Color3\.fromRGB\((\d+),\s*(\d+),\s*(\d+)\)", rar_block
    )
)

cre_block = block("Creatures")
CREATURES = [
    dict(id=m[0], name=m[1], rarity=m[2], income=int(m[3]))
    for m in re.findall(
        r'(\w+)\s*=\s*\{\s*name\s*=\s*"([^"]+)",\s*rarity\s*=\s*"(\w+)",\s*income\s*=\s*(\d+)',
        cre_block,
    )
]

# ---------------------------------------------------------------- dessin
HALF = ISLAND_SIZE / 2
REACH = HALF + SEA_MARGIN          # 330 : la vague parcourt cette distance
VIEW = REACH * 1.22                # marges autour
SIZE = 900
PAD_TOP, PAD_BOT = 70, 150

plot = SIZE - 40
scale = plot / (VIEW * 2)
cy = PAD_TOP + plot / 2
cx = SIZE / 2


def X(x):
    return cx + x * scale


def Y(z):
    return cy + z * scale


p = []
p.append(
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE + PAD_BOT - 40}" '
    f'viewBox="0 0 {SIZE} {SIZE + PAD_BOT - 40}" font-family="RobotoCondensed, Oswald, sans-serif">'
)
p.append('<rect width="100%" height="100%" fill="#0b1418"/>')
p.append(f'<text x="24" y="34" fill="#e8f1f4" font-size="21" font-weight="bold">'
         f'Tide Rush — plan de situation</text>')
p.append(f'<text x="24" y="55" fill="#7fa3ad" font-size="13">'
         f'généré depuis Config.lua · échelle réelle · 1 anneau = 75 studs</text>')

# mer
p.append(f'<circle cx="{cx}" cy="{cy}" r="{REACH * scale}" fill="#0e2f42"/>')
for i in range(1, 5):
    r = (REACH * i / 4) * scale
    p.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="#1b4a63" '
             f'stroke-width="0.6" stroke-dasharray="3 5" opacity="0.6"/>')

# ile
p.append(f'<circle cx="{cx}" cy="{cy}" r="{HALF * scale}" fill="#1d3b34" stroke="#2f6b58" stroke-width="1.5"/>')

# anneaux de rarete
for rg in RINGS:
    rm, rx = rg["rmin"] * scale, rg["rmax"] * scale
    mid = (rm + rx) / 2
    col = COLORS.get(rg["name"].split()[0], "#888")
    p.append(f'<circle cx="{cx}" cy="{cy}" r="{mid}" fill="none" stroke="{col}" '
             f'stroke-width="{rx - rm:.1f}" opacity="0.42"/>')
    ang = -math.pi / 2
    p.append(f'<text x="{cx + math.cos(ang) * (mid + 2):.1f}" y="{cy + math.sin(ang) * (mid + 2):.1f}" '
             f'fill="{col}" font-size="12" text-anchor="middle" opacity="0.95">'
             f'{rg["name"]} · {rg["rmin"]}–{rg["rmax"]}</text>')

# crique
p.append(f'<circle cx="{cx}" cy="{cy}" r="{COVE * scale}" fill="#123a4d" stroke="#4fd1c5" stroke-width="2"/>')
p.append(f'<text x="{cx}" y="{cy + 4}" fill="#7fe7dd" font-size="12" text-anchor="middle">criqué</text>')

# point de depart du joueur
hz, hzz = 0, 96
p.append(f'<circle cx="{X(hz)}" cy="{Y(hzz)}" r="5" fill="#ffd166"/>')
p.append(f'<text x="{X(hz) + 10}" y="{Y(hzz) + 4}" fill="#ffd166" font-size="11">HubSpawn</text>')

# recif (maree extreme)
p.append(f'<circle cx="{X(reef_c[0])}" cy="{Y(reef_c[1])}" r="{REEF_R * scale}" '
         f'fill="none" stroke="#c77dff" stroke-width="2" stroke-dasharray="5 4"/>')
p.append(f'<text x="{X(reef_c[0])}" y="{Y(reef_c[1] - REEF_R) - 8}" fill="#c77dff" font-size="11" '
         f'text-anchor="middle">récif à marée basse</text>')

# sens de la vague
ARR = {
    "N": (0, -REACH, 0, REACH, "vient du N, avance vers +Z"),
    "S": (0, REACH, 0, -REACH, "vient du S, avance vers -Z"),
    "E": (REACH, 0, -REACH, 0, "vient de l'E, avance vers -X"),
    "W": (-REACH, 0, REACH, 0, "vient de l'O, avance vers +X"),
}
for d, (x1, z1, x2, z2, lab) in ARR.items():
    p.append(f'<line x1="{X(x1)}" y1="{Y(z1)}" x2="{X(x2)}" y2="{Y(z2)}" '
             f'stroke="#38bdf8" stroke-width="1.6" opacity="0.5" stroke-dasharray="10 7"/>')
    p.append(f'<text x="{X(x2 * 1.06)}" y="{Y(z2 * 1.06)}" fill="#38bdf8" font-size="11" '
             f'text-anchor="middle">{d}</text>')

# echelle
sx, sz = -HALF, HALF
p.append(f'<line x1="{X(sx)}" y1="{Y(sz) + 34}" x2="{X(HALF)}" y2="{Y(sz) + 34}" '
         f'stroke="#7fa3ad" stroke-width="1.5"/>')
for v in range(int(-HALF), int(HALF) + 1, 100):
    p.append(f'<line x1="{X(v)}" y1="{Y(sz) + 28}" x2="{X(v)}" y2="{Y(sz) + 40}" stroke="#7fa3ad" stroke-width="1"/>')
    p.append(f'<text x="{X(v)}" y="{Y(sz) + 54}" fill="#7fa3ad" font-size="10" text-anchor="middle">{v}</text>')

# ---------------------------------------------------------------- legende
ly = SIZE - 78
p.append(f'<text x="24" y="{ly}" fill="#e8f1f4" font-size="13" font-weight="bold">'
         f'Chiffres lus dans le code</text>')

items = [
    (f'Île {ISLAND_SIZE:.0f}×{ISLAND_SIZE:.0f} studs, centre (0,0)'),
    (f'Criqué rayon {COVE:.0f} · 3 anneaux : ' + " · ".join(
        f"{r['name']} {r['rmin']:.0f}-{r['rmax']:.0f} ({r['maxItems']} / {r['spawnEvery']}s)" for r in RINGS)),
    (f'Vague : hauteur {W_H:.0f}, tours à {W_H + 4:.0f}, 4 directions sans répétition'),
    (f'Récif : ({reef_c[0]:.0f}, {reef_c[1]:.0f}) rayon {REEF_R:.0f}, 6 créatures, 25 s'),
]
for i, t in enumerate(items):
    p.append(f'<text x="24" y="{ly + 18 + i * 16}" fill="#9dc0c9" font-size="11.5">{t}</text>')

# roster
rx0, ry0 = SIZE / 2 + 20, ly + 2
p.append(f'<text x="{rx0}" y="{ry0}" fill="#e8f1f4" font-size="13" font-weight="bold">Roster (10 espèces)</text>')
for i, c in enumerate(CREATURES[:5]):
    yy = ry0 + 20 + i * 16
    col = COLORS.get(c["rarity"], "#888")
    p.append(f'<rect x="{rx0}" y="{yy - 9}" width="9" height="9" fill="{col}"/>')
    p.append(f'<text x="{rx0 + 16}" y="{yy}" fill="#c7dde3" font-size="11">{c["name"]}</text>')
    p.append(f'<text x="{rx0 + 168}" y="{yy}" fill="#7fa3ad" font-size="11">{c["rarity"]}</text>')
    p.append(f'<text x="{rx0 + 262}" y="{yy}" fill="#7fa3ad" font-size="11">{c["income"]}/s</text>')

p.append('</svg>')
OUT.write_text("\n".join(p), encoding="utf-8")
print("ecrit :", OUT.relative_to(ROOT))
print("anneaux :", len(RINGS), "| especes :", len(CREATURES), "| recif :", reef_c)
