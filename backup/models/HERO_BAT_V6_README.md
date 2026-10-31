# NIGHTBOUND — Hero Bat V6 (31 October 2026)

This package is a *first* 3D recreation of the purple flying hero in the supplied Nightbound v1.0 mockup, not a final photorealistic likeness. The build script authors with +Z up / +Y forward; the exported GLB converts this to **Godot Y-up / -Z forward** through a parent node.

## Files
- `Nightbound_Hero_Bat_V6_Animated.glb`: GLB 2.0 with separately pivoting wings and four animation clips: Glide, Flap, Bank_Left, Bank_Right.
- `Nightbound_Hero_Bat_V6_preview.png`: mesh-based orthographic visualization from rear and front, not an image-generation mockup.
- `build_nightbound_v6.py`: reproducible script (Python, numpy, trimesh, PIL, matplotlib).
- `Nightbound_Hero_Bat_V6_report.json`: structural verification and limitations.

## Godot 4 integration (NOT yet tested)
1. Drag GLB into the project `res://assets/models/hero/`. Godot should import a glTF scene.
2. Open imported scene; inspect wing pivot nodes `Wing_Left_Pivot` and `Wing_Right_Pivot`.
3. Check whether glTF imported animation clips `Glide`, `Flap`, `Bank_Left`, `Bank_Right` are available through AnimationPlayer.
4. Scale gameplay collider separately and attach a character controller in a wrapper scene; GLB does not contain collision.
5. Verify Y-up / -Z forward and scale before connecting gameplay controls.

## Known limitations
- No armature, skin weights or deformation inside membranes; wing root animations rotate rigid wings.
- No Godot engine validation, performance test or game scene integration.
- Stylized geometric proxy, not exact textures, fur grooming or facial animation.
- Exported geometry can be heavier than needed for mobile/web; measure draw calls after import.

**Backup status**: Documentation uploaded to GitHub; the referenced GLB/PNG/script binaries have not been uploaded by this commit.
