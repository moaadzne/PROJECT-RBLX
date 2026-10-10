"""Rend l'ile et la vague EN IMAGE, a partir des MEMES fonctions que les scripts Roblox.

Ce n'est PAS une capture du jeu : il n'y a pas de moteur, pas de lumiere, pas de rendu
Roblox, et surtout le jeu n'a jamais tourne. C'est une projection geometrique des
donnees reelles du monde, pour que la forme soit visible et verifiable avant lundi.

Ce que ca montre : la hauteur de sol reelle (la meme fonction heightAt que
build_island_terrain.luau), les materiaux reels (materialAt), les 8 lagons, la crete de
falaise, le recif, et la vague la ou elle est a l'instant demande.

Ce que ca ne montre PAS, et qu'aucune image de ce type ne peut montrer :
la lumiere, les materiaux PBR, les embruns, la crete d'ecume, l'eau en relief, et
surtout le rendu de Roblox. Un rendu flat de donnees ne vaut pas une capture : c'est
une verification de geometrie, pas un resultat visuel.

Lancement : python3 tools/world/render_island_png.py
Sortie : tools/world/island_heightmap.png
"""
import math
import os
import struct
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ISLAND = os.path.join(HERE, "build_island_terrain.luau")
CONFIG = os.path.join(os.path.dirname(os.path.dirname(HERE)), "src", "ReplicatedStorage", "Shared", "Config.lua")
OUT = os.path.join(HERE, "island_heightmap.png")

# --- Valeurs : lues dans le code, jamais inventees ---
import re
isl_src = open(ISLAND, encoding="utf-8").read()
cfg_src = open(CONFIG, encoding="utf-8").read()

def num_in(src, key, default):
    m = re.search(rf"\b{key}\s*=\s*([0-9.]+)", src)
    return float(m.group(1)) if m else default

SIZE = num_in(cfg_src, "size", 600)
COVE = num_in(cfg_src, "coveRadius", 70)
SEA_Y = num_in(cfg_src, "seaY", 0)
SPAWN_Y_MIN = num_in(cfg_src, "spawnYMin", -2)
SPAWN_Y_MAX = num_in(cfg_src, "spawnYMax", 16)
WAVE_HEIGHT = num_in(cfg_src, r"height = ([0-9.]+), -- hauteur", 30)
HALF = SIZE / 2
REACH = HALF + num_in(cfg_src, "seaMargin", 30)
REEF_Z = 335.0
REEF_R = num_in(cfg_src, "radius", 30)

LAGOON_COUNT = int(num_in(isl_src, "LAGOON_COUNT", 8))
LAGOON_RING_R = num_in(isl_src, "LAGOON_RING_R", 50)
LAGOON_RADIUS = num_in(isl_src, "LAGOON_RADIUS", 18)
CLIFF_H = num_in(isl_src, "CLIFF_HEIGHT", 30)
CLIFF_OUTER = num_in(isl_src, "CLIFF_OUTER", 74)
BREACH = num_in(isl_src, "BREACH_HALF_WIDTH", 10)

lag_angles = [(i - 1) * (2 * math.pi / LAGOON_COUNT) for i in range(LAGOON_COUNT)]

def in_breach(x, z, r):
    if r < 0.01:
        return False
    a = math.atan2(z, x)
    ha = math.atan2(BREACH, r)
    for la in lag_angles:
        if abs(math.atan2(math.sin(a - la), math.cos(a - la))) < ha:
            return True
    return False

def height_at(x, z):
    """Meme fonction que build_island_terrain.luau (fidele au code)."""
    r = math.hypot(x, z)
    if r > HALF:
        return SEA_Y - 3
    if r < COVE:
        t = r / COVE
        return SEA_Y - 2 + t * 2
    if r <= CLIFF_OUTER:
        if in_breach(x, z, r):
            return SEA_Y + 1
        return SEA_Y + CLIFF_H
    roll = math.sin(x * 0.02) * 2 + math.cos(z * 0.018) * 2
    base = SEA_Y + 2 + roll
    if base > SPAWN_Y_MAX - 2:
        base = SPAWN_Y_MAX - 2
    if base < SPAWN_Y_MIN + 1:
        base = SPAWN_Y_MIN + 1
    if r > 300:
        t = (r - 300) / (HALF - 300)
        base = base * (1 - t) + (SEA_Y - 3) * t
    return base

# --- Palette du DA (docs/DA_MONDE.md §3) ---
def lerp(a, b, t): return a + (b - a) * t
def sand(h):       # sable sec -> sable mouille
    if h < SEA_Y: return (150, 128, 92)
    return (230, 210, 168)
def water_depth(h):
    # eau : turquoise peu profond -> ocean profond
    d = max(0.0, SEA_Y - h)
    return (int(lerp(47, 13, min(1, d / 4))), int(lerp(184, 48, min(1, d / 4))), int(lerp(179, 76, min(1, d / 4))))
def rock():
    return (59, 54, 51)

def pixel(x, z):
    h = height_at(x, z)
    r = math.hypot(x, z)
    # materiaux
    is_rock = (COVE < r <= CLIFF_OUTER) and not in_breach(x, z, r)
    if is_rock:
        base = rock()
    elif h <= SEA_Y:
        return water_depth(h)
    else:
        base = sand(h)

    # Ombrage de relief. Le premier essai ne montrait PAS la crete : une derivee centrale
    # sur 2 studs ne voit pas une falaise verticale de 30 studs. On fait donc deux choses :
    #  - un eclairage par FACETTE (pente) qui accentue les fronts ;
    #  - un eclairage par EXPOSITION : si le point est cache par une hauteur devant lui
    #    (ici, plus au nord-ouest, la lumiere du couchant), on l'assombrit franchement.
    d = 2.0
    hx = height_at(x + d, z) - height_at(x - d, z)
    hz = height_at(x, z + d) - height_at(x, z - d)
    slope = max(0.0, min(1.0, 0.5 + 0.5 * (hx * 0.7 + hz * 0.7)))

    # exposition : on marche vers la lumiere (-X, -Z) et on cherche ce qui depasse
    occ = 0.0
    for step in range(1, 14):
        for ox, oz in ((-step, 0), (0, -step), (-step, -step)):
            if height_at(x + ox, z + oz) > h + 0.5:
                occ = max(occ, min(1.0, (height_at(x + ox, z + oz) - h) / 12.0))
    shadow = 1.0 - 0.55 * occ

    light = (0.55 + 0.45 * slope) * shadow
    # la crete est aussi plus claire sur son sommet (elle prend le ciel)
    if is_rock:
        light = max(light, 0.9) * 1.15
    col = tuple(min(255, int(c * light)) for c in base)
    return col

def write_png(path, w, h, rows):
    raw = b"".join(b"\x00" + bytes(row) for row in rows)
    def chunk(t, d):
        c = t + d
        return struct.pack(">I", len(d)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    open(path, "wb").write(png)

# --- Rendu ---
W = 700
STEP = 1.6  # studs par pixel
world_w = W * STEP
x0, z0 = -world_w / 2, -world_w / 2

# La vague : venue du N, elle avance vers +Z. Son FRONT est a z = -60, en plein travers
# de l'ile. On la dessille comme un mur d'eau : ecume au front, corps turquoise derriere.
wave_z = -60.0
WAVE_T = 20.0   # epaisseur du mur visible, en studs

rows = []
for py in range(W):
    z = z0 + (py + 0.5) * STEP
    row = bytearray()
    for px in range(W):
        x = x0 + (px + 0.5) * STEP
        r, g, b = pixel(x, z)

        d = abs(z - wave_z)
        if d < WAVE_T:
            t = d / WAVE_T
            if t < 0.18:
                r, g, b = 238, 245, 242      # ecume du front
            elif t < 0.55:
                r, g, b = 150, 226, 224     # corps clair
            else:
                r, g, b = 30, 120, 135      # corps profond
            # lisere sombre juste derriere le front : donne du volume au mur
            if 0.18 <= t < 0.30:
                r, g, b = int(r * 0.72), int(g * 0.78), int(b * 0.80)
        row += bytes((r, g, b))
    rows.append(row)

write_png(OUT, W, W, rows)
print(f"ecrit : {OUT} ({W}x{W}, {STEP} studs/px)")
print(f"geometrie reelle : ile {SIZE:.0f}, crique r={COVE:.0f}, lagons r={LAGOON_RADIUS:.0f}x{LAGOON_COUNT}, vague h={WAVE_HEIGHT:.0f}")
print("NOTE : projection de hauteurs. PAS une capture Roblox, PAS un rendu du jeu.")
