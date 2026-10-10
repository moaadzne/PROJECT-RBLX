"""Genere tools/world/island_plan.svg : plan de situation 2D, vu du dessus.

Toutes les positions viennent du CODE (Config.lua + build_island_terrain.luau).
Rien n'est invente : ce qui n'est pas dans le code est marque "non defini".

Lancement : python3 tools/world/make_island_plan.py
"""
import math
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))       # tools/world
ROOT = os.path.dirname(os.path.dirname(HERE))           # racine du repo
CONFIG = os.path.join(ROOT, "src", "ReplicatedStorage", "Shared", "Config.lua")
ISLAND = os.path.join(HERE, "build_island_terrain.luau")
OUT = os.path.join(HERE, "island_plan.svg")

def read_config():
    """Extrait Config.Island, Config.ExtremeTide, Config.WaveTravel de Config.lua."""
    src = open(CONFIG, encoding="utf-8").read()
    def num(key, default):
        m = re.search(key + r"\s*=\s*([0-9.]+)", src)
        return float(m.group(1)) if m else default
    def vec3(key):
        m = re.search(key, src)
        if not m:
            return None
        return [float(v) for v in m.group(1).split(",")]
    return {
        "center": vec3(r"\bcenter\s*=\s*Vector3\.new\(([^)]+)\)"),
        "size": num(r"\bsize", 600),
        "seaMargin": num(r"seaMargin", 30),
        "coveRadius": num(r"coveRadius", 70),
        "seaY": num(r"seaY", 0),
        "spawnYMin": num(r"spawnYMin", -2),
        "spawnYMax": num(r"spawnYMax", 16),
        "towerRadius": num(r"towerRadius", 16),
        "reef": vec3(r"reef\s*=\s*\{[^}]*?center\s*=\s*Vector3\.new\(([^)]+)\)"),
        "reefRadius": num(r"radius", 30),
        "rings": [(float(a), float(b)) for a, b in
                  re.findall(r"rMin\s*=\s*([0-9]+),\s*rMax\s*=\s*([0-9]+)", src)],
    }

def read_island():
    """Extrait la geometrie du generateur d'ile."""
    src = open(ISLAND, encoding="utf-8").read()
    def num(name, default):
        m = re.search(rf"local {name}\s*=\s*([0-9.]+)", src)
        return float(m.group(1)) if m else default
    return {
        "lagoonCount": int(num("LAGOON_COUNT", 8)),
        "lagoonRingR": num("LAGOON_RING_R", 50),
        "lagoonRadius": num("LAGOON_RADIUS", 18),
        "cliffHeight": num("CLIFF_HEIGHT", 30),
        "cliffOuter": num("CLIFF_OUTER", 74),
        "breachHalfWidth": num("BREACH_HALF_WIDTH", 10),
    }

cfg = read_config()
isl = read_island()

CENTER = cfg["center"] or [0, 0, 0]
CX, CZ = CENTER[0], CENTER[2]
SIZE = cfg["size"]
HALF = SIZE / 2
SEA_MARGIN = cfg["seaMargin"]
COVE = cfg["coveRadius"]
REACH = HALF + SEA_MARGIN           # 330 : portee de la vague
REEF_C = cfg["reef"] or [0, 0, 335]
REEF_R = cfg["reefRadius"]

# --- Geometrie de l'ile (memes formules que build_island_terrain.luau) ---
LAGOON_COUNT = isl["lagoonCount"]
LAGOON_RING_R = isl["lagoonRingR"]
LAGOON_RADIUS = isl["lagoonRadius"]
CLIFF_OUTER = isl["cliffOuter"]
CLIFF_H = isl["cliffHeight"]
BREACH = isl["breachHalfWidth"]

lag_angles = [(i - 1) * (2 * math.pi / LAGOON_COUNT) for i in range(LAGOON_COUNT)]
lag_xy = [(CX + math.cos(a) * LAGOON_RING_R, CZ + math.sin(a) * LAGOON_RING_R) for a in lag_angles]

def breach_half_angle(r):
    return math.atan2(BREACH, r)

def in_breach(x, z, r):
    """Meme test que le generateur : porte angulaire face a un lagon."""
    ang = math.atan2(z - CZ, x - CX)
    for la in lag_angles:
        d = abs(math.atan2(math.sin(ang - la), math.cos(ang - la)))
        if d < breach_half_angle(r):
            return True
    return False

# --- Cadre SVG ---
# Le cadre doit contenir TOUT ce qu'on dessine : l'ile (300), la portee de la vague (330)
# et le recif de repli (335 au sud). On prend donc 350 de rayon utile, sinon le recif sort.
PAD = 90
SCALE = 1.7  # px par stud
FRAME_R = 350
W = int(FRAME_R * 2 * SCALE) + PAD * 2
H = W

def px(x):
    return PAD + (x - (CX - FRAME_R)) * SCALE

def pz(z):
    # Nord (-Z) vers le haut : on inverse l'axe Z
    return PAD + (z - (CZ - FRAME_R)) * SCALE

s = []
s.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="Helvetica,Arial,sans-serif">')
s.append('<rect width="100%" height="100%" fill="#0D3B4C"/>')  # ocean au large (couleur DA #0D3B4C)

# Ile : disque de sable (rayon HALF)
s.append(f'<circle cx="{px(CX):.1f}" cy="{pz(CZ):.1f}" r="{HALF*SCALE:.1f}" fill="#E6D2A8"/>')  # sable #E6D2A8

# Anneaux d'apparition (A)
ring_cols = ["#D3BC8C", "#C9AE7E", "#BFA173"]
for i, (r0, r1) in enumerate(cfg["rings"]):
    if i < len(ring_cols):
        s.append(f'<circle cx="{px(CX):.1f}" cy="{pz(CZ):.1f}" r="{((r0+r1)/2)*SCALE:.1f}" fill="none" '
                 f'stroke="{ring_cols[i]}" stroke-width="1.2" stroke-dasharray="6 5" opacity="0.9"/>')
        s.append(f'<text x="{px(CX):.1f}" y="{pz(CZ)-((r0+r1)/2)*SCALE-4:.1f}" fill="#8A7250" font-size="11" '
                 f'text-anchor="middle">anneau {i+1}  r {int(r0)}–{int(r1)}</text>')

# Crique : disque de fond, plus bas
s.append(f'<circle cx="{px(CX):.1f}" cy="{pz(CZ):.1f}" r="{COVE*SCALE:.1f}" fill="#13707A" opacity="0.85"/>')
s.append(f'<circle cx="{px(CX):.1f}" cy="{pz(CZ):.1f}" r="{COVE*SCALE:.1f}" fill="none" '
         f'stroke="#2FB8B3" stroke-width="2.5"/>')
s.append(f'<text x="{px(CX):.1f}" y="{pz(CZ)+4:.1f}" fill="#EEF5F2" font-size="13" font-weight="bold" '
         f'text-anchor="middle">CRIQUE r={int(COVE)}</text>')

# Crete de falaise : arc epais, avec 8 trous (les breaches)
R0, R1 = COVE, CLIFF_OUTER
for deg in range(0, 360, 2):
    a = math.radians(deg)
    r = (R0 + R1) / 2
    x, z = CX + math.cos(a) * r, CZ + math.sin(a) * r
    if in_breach(x, z, r):
        continue
    # petit trait du rayon R0 a R1
    x0, z0 = CX + math.cos(a) * R0, CZ + math.sin(a) * R0
    x1, z1 = CX + math.cos(a) * R1, CZ + math.sin(a) * R1
    s.append(f'<line x1="{px(x0):.1f}" y1="{pz(z0):.1f}" x2="{px(x1):.1f}" y2="{pz(z1):.1f}" '
             f'stroke="#3B3633" stroke-width="{(R1-R0)*SCALE:.1f}" stroke-linecap="butt"/>')

# Les 8 lagons
for i, (lx, lz) in enumerate(lag_xy):
    s.append(f'<circle cx="{px(lx):.1f}" cy="{pz(lz):.1f}" r="{LAGOON_RADIUS*SCALE:.1f}" '
             f'fill="#2FB8B3" stroke="#EEF5F2" stroke-width="2"/>')
    s.append(f'<text x="{px(lx):.1f}" y="{pz(lz)+4:.1f}" fill="#0D3B4C" font-size="12" '
             f'font-weight="bold" text-anchor="middle">{i+1}</text>')

# Sortie de chaque lagon : Center + o*(Radius+5), o = direction crique -> lagon (contrat A)
for i, (lx, lz) in enumerate(lag_xy):
    d = math.hypot(lx - CX, lz - CZ)
    ox, oz = (lx - CX) / d, (lz - CZ) / d
    ex, ez = lx + ox * (LAGOON_RADIUS + 5), lz + oz * (LAGOON_RADIUS + 5)
    s.append(f'<line x1="{px(lx):.1f}" y1="{pz(lz):.1f}" x2="{px(ex):.1f}" y2="{pz(ez):.1f}" '
             f'stroke="#D9A93F" stroke-width="2.5" stroke-dasharray="5 4"/>')
    s.append(f'<circle cx="{px(ex):.1f}" cy="{pz(ez):.1f}" r="3.5" fill="#D9A93F"/>')

# Recif (marree extreme) : repli de Config.ExtremeTide
rx, rz = REEF_C[0], REEF_C[2]
s.append(f'<circle cx="{px(rx):.1f}" cy="{pz(rz):.1f}" r="{REEF_R*SCALE:.1f}" fill="#D9776A" '
         f'stroke="#B8607A" stroke-width="2" opacity="0.9"/>')
s.append(f'<text x="{px(rx):.1f}" y="{pz(rz)+4:.1f}" fill="#FFFFFF" font-size="12" font-weight="bold" '
         f'text-anchor="middle">RÉCIF r={int(REEF_R)}</text>')

# Portee de la vague : carree de -REACH a +REACH sur chaque axe
s.append(f'<rect x="{px(CX-REACH):.1f}" y="{pz(CZ-REACH):.1f}" width="{2*REACH*SCALE:.1f}" '
         f'height="{2*REACH*SCALE:.1f}" fill="none" stroke="#F2A35E" stroke-width="2" '
         f'stroke-dasharray="14 8" opacity="0.75"/>')

def arrow(x0, z0, x1, z1, col, label):
    s.append(f'<line x1="{px(x0):.1f}" y1="{pz(z0):.1f}" x2="{px(x1):.1f}" y2="{pz(z1):.1f}" '
             f'stroke="{col}" stroke-width="4" marker-end="url(#arrow)"/>')
    s.append(f'<text x="{px((x0+x1)/2):.1f}" y="{pz((z0+z1)/2)-8:.1f}" fill="{col}" font-size="14" '
             f'font-weight="bold" text-anchor="middle">{label}</text>')

s.append('<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" '
         'markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#F2A35E"/>'
         '</marker></defs>')
# Fleches de direction de vague (N/E/S/O), convention A : on les pose sur le bord de la portee,
# legerement a l'exterieur pour ne pas masquer le plan de l'ile.
A0, A1 = REACH + 6, REACH + 44
arrow(CX, CZ - A1, CX, CZ - A0, "#F2A35E", "vague venue du N → +Z")
arrow(CX + A1, CZ, CX + A0, CZ, "#F2A35E", "E → -X")
arrow(CX, CZ + A1, CX, CZ + A0, "#F2A35E", "S → -Z")
arrow(CX - A1, CZ, CX - A0, CZ, "#F2A35E", "W → +X")

# Tours : NON DEFINIES dans le code -> on les declare, on ne les invente pas
UND = [
    ("Tours (×8)", f"aucun TowerN.Center dans le code ; rayon d'exclusion {int(cfg['towerRadius'])} studs"),
    ("Épave (SO)", "aucune position dans le code"),
    ("Belvédère", "aucune position dans le code"),
]
box_h = 28 + len(UND) * 19
box_y = H - PAD - box_h - 46
s.append(f'<rect x="{PAD}" y="{box_y}" width="470" height="{box_h}" fill="#0A2530" opacity="0.88" rx="6"/>')
s.append(f'<text x="{PAD+14}" y="{box_y+20}" fill="#F2A35E" font-size="13" font-weight="bold">'
         f'NON DÉFINIS DANS LE CODE — rien n\'est inventé ici</text>')
for i, (lab, det) in enumerate(UND):
    s.append(f'<text x="{PAD+14}" y="{box_y+40+i*19}" fill="#EEF5F2" font-size="12">'
             f'· {lab} — {det}</text>')

# Echelle
sx, sy = PAD, H - PAD + 20
bar = 100 * SCALE
s.append(f'<line x1="{sx}" y1="{sy}" x2="{sx+bar}" y2="{sy}" stroke="#EEF5F2" stroke-width="3"/>')
for k in range(0, 101, 25):
    s.append(f'<line x1="{sx+k*SCALE}" y1="{sy-5}" x2="{sx+k*SCALE}" y2="{sy+5}" stroke="#EEF5F2" stroke-width="2"/>')
    s.append(f'<text x="{sx+k*SCALE}" y="{sy+20}" fill="#EEF5F2" font-size="11" text-anchor="middle">{k}</text>')
s.append(f'<text x="{sx+bar+40}" y="{sy+5}" fill="#EEF5F2" font-size="12">studs (1 unité = 1 stud)</text>')

# Nord
nx, ny = W - PAD - 60, PAD + 40
s.append(f'<line x1="{nx}" y1="{ny+40}" x2="{nx}" y2="{ny}" stroke="#EEF5F2" stroke-width="3" marker-end="url(#arrow)"/>')
s.append(f'<text x="{nx}" y="{ny+58}" fill="#EEF5F2" font-size="16" font-weight="bold" text-anchor="middle">N</text>')
s.append(f'<text x="{nx}" y="{ny+76}" fill="#EEF5F2" font-size="10" text-anchor="middle">(−Z)</text>')

# Titre
s.append(f'<text x="{PAD}" y="{PAD-30}" fill="#FFFFFF" font-size="22" font-weight="bold">'
         f'Ride the Tsunami — plan de situation (P1-36)</text>')
s.append(f'<text x="{PAD}" y="{PAD-8}" fill="#BFD3DC" font-size="13">'
         f'Île {int(SIZE)}×{int(SIZE)} studs · crique r={int(COVE)} · {LAGOON_COUNT} lagons r={int(LAGOON_RADIUS)} '
         f'· créte {int(COVE)}–{int(CLIFF_OUTER)} (h={int(CLIFF_H)}) · vague ±{int(REACH)} · généré par make_island_plan.py</text>')

# Legende
ly = PAD + 6
legend = [
    ("#E6D2A8", "Île / sable (≤ 300 studs)"),
    ("#13707A", "Crique — à l'abri de la vague"),
    ("#3B3633", "Crête de falaise, h = %d (protège la crique)" % int(CLIFF_H)),
    ("#2FB8B3", "Lagon (Center + Radius, contrat A)"),
    ("#D9A93F", "Sortie du lagon : Center + o·(Radius+5)"),
    ("#D9776A", "Récif marée extrême (repli Config.ExtremeTide)"),
    ("#F2A35E", "Portée de la vague ±%d, 4 directions" % int(REACH)),
]
s.append(f'<rect x="{PAD}" y="{ly}" width="392" height="{22+len(legend)*20}" fill="#0A2530" opacity="0.82" rx="6"/>')
s.append(f'<text x="{PAD+14}" y="{ly+20}" fill="#FFFFFF" font-size="14" font-weight="bold">LÉGENDE</text>')
for i, (col, txt) in enumerate(legend):
    yy = ly + 40 + i * 20
    s.append(f'<rect x="{PAD+14}" y="{yy-10}" width="16" height="12" fill="{col}" stroke="#EEF5F2" stroke-width="1"/>')
    s.append(f'<text x="{PAD+38}" y="{yy}" fill="#EEF5F2" font-size="12">{txt}</text>')

s.append('</svg>')

open(OUT, "w", encoding="utf-8").write("\n".join(s))
print(f"écrit : {OUT}  ({W}×{H} px)")
print(f"source : Config.lua + build_island_terrain.luau")
