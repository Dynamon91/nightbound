# Nightbound — Asset Pack 01: 3D Stylized Concept Art

## Contents
- `nightbound_asset_pack_01_concept_sheet.png` — AI-generated concept sheet for visual reference.
- This README — scope, compatibility notes, and asset status.

## Compatibility review
The existing project was checked against its `project.godot`, `README.md`, `scenes/main.tscn`, `MILESTONES.md`, and `reference/MOCKUPS_AND_INSPIRATION.md`.

- Target project: Godot 4.x, Compatibility renderer (`gl_compatibility`).
- The project is an original 3D third-person exploration-platformer starring a fantasy bat.
- The main scene bootstraps the world through `scripts/main.gd`; the current world contains procedural/prototype geometry, a bat, platforms, bridge, trees, gate and collectibles.
- For future real models, prefer `.glb`, StandardMaterial3D-compatible materials, sensible pivots/scales, and collision shapes checked against gameplay. These are handoff recommendations, not files included in this pack.

## Concept groups
1. Hero fantasy bat — silhouette, face, wing shape and animation-pose references.
2. Enemy proposals — goblin, stone golem, forest spirit, flying creature and cave spider.
3. Veilwood boss proposal — branching silhouette and violet magical core.
4. Environment kit — modular rocks/platforms, trees, ruins/arches, bridge, lanterns and crystals.
5. Collectibles and props — crystals, Moonseeds, chest, key and scroll.

## Important status distinction
- **Generated:** concept-sheet PNG and this README.
- **Added to repository:** `reference/ASSET_PACK_01_3D_CONCEPTS.md` (documentation commit `b193c6f1ad4d1727154589aca35e2dc6ccef0729`).
- **Not generated:** production 3D mesh files (`.glb`), rigged models, animation clips, game-ready texture sets or collision resources.
- **Not integrated/verified:** no asset from this concept sheet has been imported into Godot or tested in a running game.
- Compatibility check means project settings and scene architecture were reviewed; it does not mean the concept image itself is a compatible game asset.

The image is AI-generated concept art, not an in-game screenshot and not an actual 3D model.