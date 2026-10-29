# Nightbound — Asset Pack 01: 3D Stylized Concept Art

**Status:** concept sheet generated; first hero-bat blockout model now generated separately. Neither is integrated into the playable scene.  
**Project checked:** Godot 4.x, Compatibility renderer (`gl_compatibility`), 1280×720 viewport.  
**Reference date:** 2026-10-29.

## Purpose

Establish stylized 3D direction for Nightbound and guide future modeling/material/rig work. The concept sheet is a visual reference; the separate hero-bat GLB is a real low-poly blockout, not a finished production model.

## Repository compatibility check

Reviewed `project.godot`, `README.md`, `scenes/main.tscn`, `MILESTONES.md`, and `reference/MOCKUPS_AND_INSPIRATION.md`.

- Project is an original third-person 3D exploration-platformer starring a fantasy bat.
- Renderer is Godot Compatibility; use conservative StandardMaterial3D/PBR features and verify materials in engine.
- The main scene builds the world through `scripts/main.gd`; the current hero and environment include procedural/prototype geometry.
- Integrate incrementally. Do not replace the current hero until scale, orientation, materials, collisions, and runtime appearance are checked.

## Pack art direction

1. **Hero bat** — compact body, expressive eyes, broad plum membrane wings; the new GLB is an initial geometric blockout.
2. **Environment kit** — modular cliffs/platforms, rocks, trees, arch/ruins, bridge, lanterns and purple crystals.
3. **Veilwood boss concept** — branching silhouette and violet magical core; not a confirmed implemented boss.
4. **Enemy concepts** — goblin, stone golem, forest spirit, flying creature and cave spider; proposals, not confirmed current enemies.
5. **Collectibles/props** — crystals, Moonseeds, chest, key and scroll; reuse existing gameplay systems where appropriate.

## Technical handoff

- Preferred mesh format: `.glb`.
- The generated hero blockout faces toward `-Z`, uses `Y` as up, and is approximately 1.98 scene units tall including ears.
- The blockout uses separate low-poly mesh parts and PBR materials; it has no skeleton, skin weights, animation clips, collision shapes or production texture maps.
- Future assets should have gameplay-aligned pivots/collisions, readable silhouettes, reusable materials, and no dependence on renderer-specific effects.

## Asset status

| Item | Status |
|---|---|
| Concept sheet PNG | Generated; not integrated |
| Hero bat GLB blockout | Generated and GLB-load validated outside Godot; not integrated or engine-verified |
| This design brief | Added to repository |
| Rigged/animated production model | Not generated |
| Imported Godot scene/materials/collisions | Not integrated or verified |
| Compatibility review | Project settings/scene architecture reviewed; no Godot import or runtime test for the new model yet |

## Next integration steps

1. Import `nightbound_bat_hero_blockout.glb` into a temporary Godot test scene.
2. Check scale, facing direction, materials and import warnings using the Compatibility renderer.
3. Add collision separately and compare against the existing player in gameplay camera.
4. Only then replace the procedural hero and run CI plus a visible gameplay screenshot check.

## Provenance

The concept sheet is AI-generated concept art, not a gameplay screenshot or a mesh. The hero-bat GLB is a procedurally generated low-poly blockout; its successful load by a GLB parser does not prove Godot compatibility. Do not label either asset as integrated until the engine check passes.