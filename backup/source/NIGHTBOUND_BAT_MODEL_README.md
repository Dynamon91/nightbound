# Nightbound — Hero Bat 3D Blockout

- File: `nightbound_bat_hero_blockout.glb`
- Format: glTF 2.0 binary (GLB), exportable/importable by Godot 4.x.
- Contents: stylized low-poly bat blockout assembled from separate mesh parts with PBR materials.
- Orientation: Y up; character faces toward -Z. Approximate height 1.7 scene units including ears.
- Intended use: first real geometry/proportion blockout for visual review and import testing.

## Status
**Generated mesh file; not yet integrated into the Nightbound scene and not runtime-verified in Godot.** No skeleton, skin weights, animation clips, collision shapes, or production texture maps are included. Wings are static meshes. The model is a first-pass procedural blockout, not the final concept-sheet character.

## Suggested Godot import check
1. Copy the GLB into `res://assets/models/`.
2. Open it in Godot 4.x using the project's Compatibility renderer.
3. Check scale/orientation/material appearance and import warnings.
4. Create a test scene, add collision separately, and compare proportions against the existing player.
5. Only replace the existing procedural hero after in-game inspection and a passing CI run.