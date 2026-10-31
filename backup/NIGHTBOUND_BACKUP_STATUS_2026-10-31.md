# Nightbound — Backup status (updated 2026-10-31)

## Verified GitHub backups

**Uploaded to the `main` branch and checked against the repository tree:**

- **3D characters:** original bat blockout GLB and Hero Bat V3, V4, V5 and V6 Animated GLBs, with separate PNG previews.
- **Modeling source:** Blender V2/V2.1 and Python generator scripts V3–V6, plus technical readmes.
- **Concept and menu art:** character lineup, main-world/castle references, generated menu PNG concepts, original hero reference crop, and the original 3D concept ZIP.
- **Intro:** original MP4, compact playable GIF, original 720×405 GIF split *losslessly* into six parts with a `restore_gif.py` script and SHA-256 verification.
- **Interactive menu:** full original standalone HTML (embedded background) and a smaller fallback HTML file.
- **Creature/model packs:** NIGHTBOUND_CHARACTER_CREATURE_PACK_04.zip, NIGHTBOUND_CREATURES_NPCS_PACK_05.zip, NIGHTBOUND_MODELS_PACK_06.zip, NIGHTBOUND_HERO_BAT_V6_PACK.zip.
- **Music:** V15 music ZIP in six lossless parts, with `restore_music_v15.py` and SHA-256 verification.
- **File inventory:** `backup/manifests/NIGHTBOUND_BACKUP_MANIFEST_2026-10-31.json` lists 145 local files and SHA-256 checksums.

At this update, `backup/` has **58 tracked files, about 63.85 MB** (including recovery scripts and split parts). This was verified from GitHub's recursive tree.

## Full local backup (not all uploaded to GitHub)

All **13 separate ZIP archive parts** of the original backup and the complete checksum manifest were also uploaded successfully to the user's **ChatGPT Library**, folder `/Nightbound/Backup_2026-10-31/` (approximately 302 MB of ZIP files).

**Important:** The GitHub backup contains many important assets, but **not every one of the 145 original files**. Remaining prior music versions and duplicate historical archives are preserved in the Library ZIP backups. A full GitHub mirror of all archive bytes has not been claimed.

## Recoverable files

- `backup/assets/models/` — GLB hero model iterations
- `backup/assets/previews/` — model PNG previews
- `backup/assets/concepts/` — character/world concept art
- `backup/assets/menu/` — menu artwork + original HTML menu
- `backup/assets/intro/` — MP4, small playable GIF and original GIF backup parts
- `backup/assets/music/v15/` — newest music ZIP backup parts
- `backup/packages/` — other asset packs

Follow each split archive's README and check the checksum before using it. Normal project files and original mockup remain in the repository root.

## Implementation vs concept

These assets are backed up, **not** all integrated or engine-tested in Godot 4. Concept images are not playable levels, the menu's browser save slots are only a demo, and the animated GLB has not passed an in-engine integration test.
