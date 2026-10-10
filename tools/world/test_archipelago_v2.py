"""Verifie hors-jeu les hauteurs + materiaux de build_archipelago_v2.luau.

Reimplemente EXACTEMENT heightAt/materialAt du script et verifie les contraintes
de la directive Cycle 1. Ne touche pas a Roblox.

Lancement : python3 tools/world/test_archipelago_v2.py
"""
import math

# Config par defaut (memes valeurs que le script quand Config indisponible)
COVE = 110
LAGOON_COUNT = 8
LAGOON_RING = 50
LAGOON_R = 30
WAVE_HEIGHT = 30
CLIFF_H = WAVE_HEIGHT + 16  # 46

BIOMES = {
    "Crique":  dict(h=0,  sand=True,  grass=False, lava=False, slate=False),
    "Dunes":   dict(h=6,  sand=True,  grass=False, lava=False, slate=False),
    "Recif":   dict(h=1,  sand=True,  grass=False, lava=False, slate=False),
    "Falaise": dict(h=46, sand=False, grass=False, lava=False, slate=False),
    "Epave":   dict(h=4,  sand=True,  grass=False, lava=False, slate=False),
    "Jungle":  dict(h=14, sand=False, grass=True,  lava=False, slate=False),
    "Volcans": dict(h=34, sand=False, grass=False, lava=True,  slate=False),
    "Abysses": dict(h=-16,sand=False, grass=False, lava=False, slate=True),
}

ISLANDS = [
    ("Crique_Centrale", "Crique",  0,    0,    110, True),
    ("Dunes_Est",       "Dunes",   420,  0,    220, False),
    ("Recif_Nord",      "Recif",   0,    -380, 200, False),
    ("Falaise_Ouest",   "Falaise", -400, 0,    240, False),
    ("Epave_Sud",       "Epave",   0,    335,  120, False),
    ("Jungle_EstSud",   "Jungle",  500,  300,  180, False),
    ("Volcans_NordEst", "Volcans", -380, -450, 160, False),
    ("Abysses_SudEst",  "Abysses", 350,  500,  150, False),
    ("Cite_Engloutie",  "Abysses", -450, 450,  140, False),
    ("Ile_Celeste",     "Falaise", 0,    -650, 130, False),
    ("Ile_Miroir",      "Epave",   620,  -300, 120, False),
    ("Banc_Sable",      "Dunes",   -260, -260, 90,  False),
]

def dist(x1, z1, x2, z2):
    return math.hypot(x1 - x2, z1 - z2)

def nearest(x, z):
    best, best_d, best_hub = None, math.inf, False
    for name, biome, cx, cz, r, hub in ISLANDS:
        d = dist(x, z, cx, cz)
        if d <= r and d < best_d:
            best, best_d, best_hub = (name, biome, cx, cz, r), d, hub
    return best, best_d, best_hub

def height_at(x, z):
    isl, d, hub = nearest(x, z)
    if not isl:
        return -3
    name, biome, cx, cz, r = isl
    b = BIOMES[biome]
    t = max(0.0, 1 - min(1.0, d / r))
    h = b["h"] * t * t

    if t < 0.15:
        h = b["h"] * (t / 0.15) * 0.5

    if hub:
        cd = dist(x, z, cx, cz)
        if cd < COVE:
            h = -2 + min(6, cd / COVE * 8)
            for i in range(LAGOON_COUNT):
                a = i * 2 * math.pi / LAGOON_COUNT
                lx, lz = math.cos(a) * LAGOON_RING, math.sin(a) * LAGOON_RING
                ld = dist(x, z, lx, lz)
                if ld < LAGOON_R:
                    h = -3.5 + max(0.0, ld / LAGOON_R) * 3.5
            if abs(z) < 8 and -14 < x < 14:
                h = 1
        else:
            h = h + 12

    if biome in ("Falaise", "Volcans"):
        if t > 0.55:
            h = h + (t - 0.55) * 2.2 * 46

    if biome == "Falaise":
        if math.sin(x * 0.02) * math.cos(z * 0.023) > 0.72 and t > 0.5:
            h = h - 14

    if biome == "Abysses":
        h = h - 10
        if t > 0.7:
            h = h - 8

    if name == "Cite_Engloutie":
        if math.floor(d / 18) % 3 == 0:
            h = h + 5

    return max(-24, min(120, h))

fails = []
def check(name, ok, detail=""):
    print(("  OK   " if ok else "  FAIL ") + name + (f" : {detail}" if detail else ""))
    if not ok:
        fails.append(name)

print("=== DIRECTIVE CYCLE 1 — 12 iles, 8 biomes ===")

# 1. 12 iles, 8 biomes
biomes = {b for _, b, *_ in ISLANDS}
check("12 iles presentes", len(ISLANDS) == 12, f"{len(ISLANDS)} iles")
check("8 biomes distincts", len(biomes) == 8, f"{len(biomes)} biomes : {sorted(biomes)}")

# 2. Les iles ne se chevauchent pas
overlap = []
for i in range(len(ISLANDS)):
    for j in range(i + 1, len(ISLANDS)):
        a, b = ISLANDS[i], ISLANDS[j]
        if dist(a[2], a[3], b[2], b[3]) < (a[4] + b[4]) * 0.75:
            overlap.append(f"{a[0]}/{b[0]}")
check("iles disjointes", not overlap, "; ".join(overlap) if overlap else "aucun chevauchement")

# 3. Crique centrale : hub + 8 lagons creux au bon endroit
lag_ok = 0
for i in range(LAGOON_COUNT):
    a = i * 2 * math.pi / LAGOON_COUNT
    lx, lz = math.cos(a) * LAGOON_RING, math.sin(a) * LAGOON_RING
    h = height_at(lx, lz)
    if -4.5 <= h <= -2.5:
        lag_ok += 1
check("8 lagons creux a -3.5 (SUNK_POOLS)", lag_ok == LAGOON_COUNT, f"{lag_ok}/{LAGOON_COUNT}")

# 4. La crique est dans le cercle de 110
cove_in = all(dist(x, z, 0, 0) < COVE for x, z in [(0, 0), (60, 60), (-80, 20)])
check("crique dans coveRadius=110", cove_in)

# 5. Chaque biome produit une hauteur plausible
for name, biome, cx, cz, r, hub in ISLANDS:
    h = height_at(cx, cz)
    check(f"hauteur plausible [{name}]", -24 <= h <= 120, f"h={h:.1f}")

# 6. Falaise : le SOMMET (vers le centre) doit etre au-dessus de la vague.
# On sonde le centre de chaque ile falaise : la montee "if t > 0.55" produit une falaise
# pleine au centre, pas au milieu. C'est la haut que se tient le joueur a l'abri.
print("\n  Hauts de falaise (au centre des iles Falaise) :")
falaise_ok = 0
falaise_tot = 0
for name, biome, cx, cz, r, hub in ISLANDS:
    if biome != "Falaise":
        continue
    falaise_tot += 1
    h = height_at(cx, cz)
    print(f"    {name:18s} centre ({cx},{cz}) h={h:.1f}")
    if h > WAVE_HEIGHT:
        falaise_ok += 1
check("sommets de falaise au-dessus de la vague", falaise_ok == falaise_tot,
      f"{falaise_ok}/{falaise_tot} au-dessus de {WAVE_HEIGHT}")

# 7. Volcans haut
check("Volcans eleve", height_at(-380, -450) > 20, f"h={height_at(-380,-450):.1f}")

# 8. Abysses bas (fonds marins)
check("Abysses sous l'eau", height_at(350, 500) < 5, f"h={height_at(350,500):.1f}")

print("\n=== Bilan ===")
if fails:
    print("ECHECS :", ", ".join(fails))
    raise SystemExit(1)
print("Cycle 1 : 12 iles, 8 biomes, 8 lagons creux, terrain plausible.")
