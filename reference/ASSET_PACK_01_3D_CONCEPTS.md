# Nightbound — Asset Pack 01: 3D Stylized Concept Art

**Status:** generated concept/reference package; not integrated game assets.  
**Project checked:** Godot 4.x, Compatibility renderer (gl_compatibility), 1280×720 viewport.  
**Reference date:** 2026-10-29.

## Purpose

Define a consistent stylized 3D art direction for Nightbound and guide future modeling/material/rig work. This document and the companion concept sheet are visual references, not production-ready meshes.

## Repository compatibility check

Reviewed the current project.godot, README.md, scenes/main.tscn, MILESTONES.md, and reference/MOCKUPS_AND_INSPIRATION.md.

- Project identifies itself as an original third-person 3D exploration-platformer starring a fantasy bat.
- Godot project uses the Compatibility renderer; target assets should avoid depending on renderer-specific effects and should use conservative material/shader features.
- The main scene delegates world creation to scripts/main.gd; current level geometry and many props are procedural/prototype quality.
- Existing world already includes a bat protagonist, valley platforms, bridge, trees, realm gate, crystals and Veilwood elements. The first production asset pass should replace or improve those existing elements incrementally, not assume a separate character/world architecture.
- The README explicitly distinguishes generated concept art from screenshots of the running game.

## Pack contents / art direction

1. **Hero bat** — preserve the existing original fantasy-bat identity. Strong readable silhouette, expressive eyes, compact body, broad membrane wings; front/side/back and wing poses are reference targets only.
2. **Environment kit** — modular cliffs/platforms, rocks, trees, arch/ruins, bridge, lanterns and purple crystals; make pieces reusable and collision-friendly.
3. **Veilwood boss concept** — antler/branch silhouette with violet magical core. Boss encounter and finished boss assets are not yet confirmed implemented.
4. **Enemy concepts** — goblin, stone golem, forest spirit, flying creature and cave spider. These are proposals, not confirmed current in-game enemies.
5. **Collectibles/props** — crystals, Moonseeds, chest, key and scroll. Reuse the project's existing collectible concepts where appropriate rather than duplicating gameplay systems.

## Technical handoff targets (not yet produced)

- Preferred mesh delivery: .glb for authored models, with source files retained separately when available.
- Materials: Godot StandardMaterial3D-compatible PBR maps; use emission sparingly for magical accents. Texture targets of 1024–2048 px are a proposal, not existing deliverables.
- Scale/pivots: agree a project-wide scale and origin for each asset family before production; align collision shapes with gameplay, not merely the rendered silhouette.
- Modularity: platform tops should connect cleanly; avoid visible seams and excessive overhang where the player lands.
- Optimization: reuse materials/textures, keep silhouette detail readable at gameplay camera distance, and use LODs only where justified by actual scene complexity.
- Animation: hero needs an animation-ready rig before a turnaround or pose sheet can be treated as a production model.

## Asset status — be precise

| Item | Status |
|---|---|
| Generated concept sheet image | **Generated, not integrated** |
| This design brief | **Added to repository** |
| Production-ready 3D meshes (.glb) | Not generated |
| Rigged/animated character models | Not generated |
| Imported Godot scenes/materials/collisions | Not integrated or verified |
| Compatibility check | Project settings and scene architecture reviewed; no asset import/build test was run for this concept-only pack |

## Next integration steps

1. Select one high-value asset (recommended: hero bat or modular Moonlit Valley rock/platform).
2. Produce a real mesh and any required texture/source files.
3. Import into Godot 4.x Compatibility renderer and inspect materials, scale, pivot and collisions.
4. Replace one existing procedural element behind a reversible scene change.
5. Run the project's Godot CI/import and visible gameplay screenshot checks; record the commit and verification result before marking the asset integrated.

## Provenance

The companion image is AI-generated concept art for Nightbound. It is not a screenshot of the running game, not a mesh, and not proof of compatibility. Do not label any concept shown here as an implemented asset.