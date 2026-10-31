# Nightbound intro GIF — lossless backup

The original **720×405, 80-frame, 8-second** intro GIF is stored losslessly in six binary parts because a single large API upload was rejected. This is a binary split, **not** a re-encoding.

To restore it, download the six `.part01` ... `.part06` files into one directory and run:

```bash
python restore_gif.py
```

The script reassembles `Nightbound_Intro_Loop.gif` and verifies SHA-256:
`e617bea4d6b9171f658e0cf29603e4c2823987e39e241f34db6412a9abffb49c`

The smaller [directly playable GIF](../Nightbound_Intro_Loop_GitHub_Small.gif) and original [MP4](../Nightbound_Intro_Cinematic.mp4) are also available.

**Important:** The 320×180 GIF is a lighter preview. These parts reconstruct the original, higher-resolution GIF byte-for-byte.
