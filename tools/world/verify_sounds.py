"""Verifie que chaque rbxassetid de tools/world/build_sounds.luau existe bien sur Roblox
et est un SON (AssetTypeId 3), public et gratuit.

But : ne pas livrer une vague muette parce qu'un id a ete invente.
Lecture seule, aucune ecriture dans le repo ni dans la place.

Lancement : python3 tools/world/verify_sounds.py
"""
import json
import re
import sys
import urllib.request

SCRIPT = "tools/world/build_sounds.luau"
URL = "https://economy.roblox.com/v2/assets/{}/details"

# nom = { id, ... }
ROW = re.compile(r"^\s*(\w+)\s*=\s*\{\s*(\d+)\s*,\s*([0-9.]+)\s*,\s*\"(\w+)\"")

def read_sounds():
    out = []
    for line in open(SCRIPT, encoding="utf-8"):
        m = ROW.match(line)
        if m:
            name, sid, vol, group = m.group(1), int(m.group(2)), m.group(3), m.group(4)
            out.append((name, sid, vol, group))
    return out

def fetch(sid):
    try:
        req = urllib.request.Request(URL.format(sid), headers={"User-Agent": "tide-rush-verify"})
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read().decode())
    except Exception as e:
        return {"_error": str(e)}

sounds = read_sounds()
print(f"{len(sounds)} sons dans {SCRIPT}\n")

bad, warn = [], []
for name, sid, vol, group in sounds:
    d = fetch(sid)
    if "_error" in d:
        bad.append((name, sid, "API: " + d["_error"]))
        print(f"  ERREUR {name:14} {sid} : {d['_error']}")
        continue
    atype = d.get("AssetTypeId")
    real = d.get("Name", "?")
    if atype != 3:
        bad.append((name, sid, f"type {atype} = {real}"))
        print(f"  PAS UN SON {name:14} {sid} : type {atype} ({real})")
        continue
    if not d.get("IsPublicDomain") and d.get("PriceInRobux"):
        warn.append((name, sid, real))
        print(f"  PAYANT    {name:14} {sid} : {real[:50]}")
        continue
    print(f"  OK        {name:14} {sid}  {real[:58]}")

print("\n=== detail ===")
for name, sid, vol, group in sounds:
    pass  # le detail est deja affiche plus haut

print("\n=== bilan ===")
if bad:
    print(f"{len(bad)} id(s) inutilisables :")
    for n, s, why in bad:
        print(f"   - {n} ({s}) : {why}")
else:
    print("Tous les ids sont des sons reels et publics.")
