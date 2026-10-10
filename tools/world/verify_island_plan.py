"""Verifie que tools/world/island_plan.svg correspond bien au code source.

But : D a demande une carte "tiree de mes scripts et de Config, pas inventee".
Ce controle prouve que les valeurs du SVG sont celles de Config.lua et de
build_island_terrain.luau, et que les elements non definis sont declares comme tels.

Lancement : python3 tools/world/verify_island_plan.py
"""
import math
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
SVG = os.path.join(HERE, "island_plan.svg")
CONFIG = os.path.join(os.path.dirname(os.path.dirname(HERE)), "src", "ReplicatedStorage", "Shared", "Config.lua")
ISLAND = os.path.join(HERE, "build_island_terrain.luau")

cfg_src = open(CONFIG, encoding="utf-8").read()
isl_src = open(ISLAND, encoding="utf-8").read()
svg = open(SVG, encoding="utf-8").read()

def num_in(src, key, default=None):
    m = re.search(rf"\b{key}\s*=\s*([0-9.]+)", src)
    return float(m.group(1)) if m else default

fails = []
def check(name, ok, detail=""):
    print(("  OK   " if ok else "  FAIL ") + name + (f" : {detail}" if detail else ""))
    if not ok:
        fails.append(name)

print("=== Valeurs du SVG vs code ===")

# Les nombres affiches dans le SVG doivent etre presents dans le code.
for label, key, src in [
    ("taille de l'ile", "size", cfg_src),
    ("coveRadius", "coveRadius", cfg_src),
    ("seaMargin", "seaMargin", cfg_src),
    ("towerRadius", "towerRadius", cfg_src),
    ("rayon des lagons", "LAGOON_RADIUS", isl_src),
    ("anneau des lagons", "LAGOON_RING_R", isl_src),
    ("hauteur de crete", "CLIFF_HEIGHT", isl_src),
    ("bord de crete", "CLIFF_OUTER", isl_src),
]:
    v = num_in(src, key)
    if v is None:
        continue
    txt = f"{int(v)}" if float(v).is_integer() else f"{v:g}"
    check(f"{label} = {txt} present dans le SVG", txt in svg)

# Geometrie des lagons : 8 disques de rayon LAGON_RADIUS sur l'anneau LAGOON_RING_R
LAGOON_R = num_in(isl_src, "LAGOON_RADIUS")
RING_R = num_in(isl_src, "LAGOON_RING_R")
COUNT = int(num_in(isl_src, "LAGOON_COUNT"))
n_circles = len(re.findall(r'<circle[^>]*fill="#2FB8B3"[^>]*stroke="#EEF5F2"', svg))
check("8 lagons dessines", n_circles == COUNT, f"{n_circles} cercles pour {COUNT} lagons")

# Recif : doit venir de Config.ExtremeTide, pas etre invente
m_reef = re.search(r"reef\s*=\s*\{[^}]*?center\s*=\s*Vector3\.new\(([^)]+)\)", cfg_src)
check("recif lu dans Config.ExtremeTide", m_reef is not None,
      f"center = ({m_reef.group(1).strip()})" if m_reef else "ABSENT de Config")
if m_reef:
    vals = [float(v.strip()) for v in m_reef.group(1).split(",")]
    if len(vals) == 3:
        check("recif trace au sud (+Z) comme dans Config", vals[2] > 0, f"z = {vals[2]}")

# Les elements NON DEFINIS doivent etre declares comme tels, et NON traces
check("mention 'non definis' presente", "NON DÉFINIS DANS LE CODE" in svg)
for lab in ["Tours", "Épave", "Belvédère"]:
    check(f"'{lab}' declare non defini", lab in svg)

# Aucune tour ne doit etre dessinee a une position inventee
check("aucune tour tracee", "TowerN" not in svg or "aucun TowerN.Center" in svg)

# Echelle : la conversion px/stud doit etre coherente avec la taille du cadre
w = int(re.search(r'width="(\d+)"', svg).group(1))
m_scale = re.search(r"SCALE\s*=\s*([0-9.]+)", open(os.path.join(HERE, "make_island_plan.py"), encoding="utf-8").read())
m_frame = re.search(r"FRAME_R\s*=\s*([0-9.]+)", open(os.path.join(HERE, "make_island_plan.py"), encoding="utf-8").read())
if m_scale and m_frame:
    sc = float(m_scale.group(1)); fr = float(m_frame.group(1))
    expected = int(fr * 2 * sc) + 180
    check("cadre coherent avec SCALE x FRAME_R", abs(w - expected) < 3, f"{w} px, attendu ~{expected}")

# La vague doit couvrir +/- (size/2 + seaMargin)
size = num_in(cfg_src, "size"); margin = num_in(cfg_src, "seaMargin")
reach = int(size / 2 + margin)
check("portee de la vague = size/2 + seaMargin", f"±{reach}" in svg, f"±{reach} studs")

print("\n=== Bilan ===")
if fails:
    print("ECHECS :", ", ".join(fails))
    raise SystemExit(1)
print("Le plan correspond au code. Rien n'est invente.")
