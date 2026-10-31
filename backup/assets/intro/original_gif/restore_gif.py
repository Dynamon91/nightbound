#!/usr/bin/env python3
"""Reconstruct the original Nightbound intro GIF from GitHub backup parts."""
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parent
name = "Nightbound_Intro_Loop.gif"
expected = "e617bea4d6b9171f658e0cf29603e4c2823987e39e241f34db6412a9abffb49c"
parts = [root / f"{name}.part{i:02d}" for i in range(1, 7)]
missing = [str(p) for p in parts if not p.is_file()]
if missing:
    raise SystemExit("Missing: " + ", ".join(missing))

output = root / name
sha = hashlib.sha256()
with output.open("wb") as f:
    for part in parts:
        data = part.read_bytes()
        sha.update(data)
        f.write(data)

if sha.hexdigest() != expected:
    output.unlink(missing_ok=True)
    raise SystemExit("Checksum mismatch; restored file deleted.")

print(f"Restored and verified: {output} ({output.stat().st_size:,} bytes)")
