# Nightbound — Hero Bat Blockout Scene

**Model scene:** `scenes/assets/bat_hero_blockout.tscn`  
**Preview scene:** `scenes/assets/bat_hero_preview.tscn`  
**Status:** both scenes added to the repository. The model is not yet used by the playable main scene.

## Contents

- Low-poly body and head
- Muzzle, ears, feet
- Two simplified wings
- Glowing lavender eyes
- StandardMaterial3D materials and built-in primitive meshes
- Isolated preview scene with camera, ground plane, environment, and two lights

## Compatibility notes

- Designed for Godot 4.x and the project's Compatibility renderer.
- Faces forward along `-Z`; `Y` is up.
- Uses built-in mesh resources; no external texture files are required.
- This is a visual blockout, not a production character: no skeleton, skinning, animation clips, collision, or gameplay controller.
- The wing shapes are deliberately simple blockout geometry; they are not yet a sculpted membrane silhouette.
- The preview is a separate scene and does not change the configured main scene.

## Verification status

- Scene files committed and readable back from GitHub.
- Local Godot executable was not available in the current working environment, so no local engine import or visual runtime test is claimed.
- The repository's Godot 4.3 CI workflow should parse/import these scenes on the next run. Engine compatibility remains pending until that result is inspected.

## Safe integration plan

1. Run the repository's Godot 4.3 import/parse workflow.
2. Open `res://scenes/assets/bat_hero_preview.tscn` to inspect silhouette, materials, and scale in isolation.
3. Compare against the current procedural hero from the gameplay camera.
4. Only replace the main-scene hero after visual and movement checks; keep player collision and movement controller independent of the render model.
