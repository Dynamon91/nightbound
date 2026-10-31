# Nightbound music V15 — verified lossless backup

The original `NIGHTBOUND_MUSIC_V15.zip` (10,305,968 bytes) is stored as six binary parts because the upload connector rejects larger single requests.

Run `python restore_music_v15.py` in this directory to concatenate the parts and verify SHA-256:
`c5716e08aeccf08fb07958b5b6fc19df5a5555343eae99132185477c8874019d`.

The six `.part01` ... `.part06` files reconstruct the original ZIP **byte-for-byte**. Older music versions V1–V14 are preserved in the Nightbound ChatGPT Library backup, but are not implied to be uploaded to GitHub by this entry.

This archive contains game-development audio assets, not a verified in-game Godot audio integration.
