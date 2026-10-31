#!/usr/bin/env python3
"""Restore the original Nightbound music V15 ZIP with SHA-256 verification."""
from pathlib import Path
import hashlib

base = Path(__file__).resolve().parent
name = "NIGHTBOUND_MUSIC_V15.zip"
expect = "c5716e08aeccf08fb07958b5b6fc19df5a5555343eae99132185477c8874019d"
parts = [base / f"{name}.part{i:02d}" for i in range(1, 7)]
missing = [str(x) for x in parts if not x.is_file()]
if missing:
    raise SystemExit("Missing backup parts: " + ", ".join(missing))
dst = base / name
hasher = hashlib.sha256()
with dst.open("wb") as output:
    for part in parts:
        data = part.read_bytes()
        hasher.update(data)
        output.write(data)
if hasher.hexdigest() != expect:
    dst.unlink(missing_ok=True)
    raise SystemExit("Checksum mismatch: restored ZIP discarded.")
print(f"Restored {dst}: {dst.stat().st_size:,} bytes; SHA-256 OK")
