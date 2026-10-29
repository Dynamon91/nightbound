# Nightbound — Hero Bat Blockout Scene

**Scene:** `scenes/assets/bat_hero_blockout.tscn`
**Status:** added to repository as a reusable native Godot scene. Not yet used by the playable main scene.

## Contents

- Low-poly body and head
- Muzzle, ears, feet
- Two simplified wings
- Glowing lavender eyes with white glints
- StandardMaterial3D materials and built-in primitive meshes only

## Compatibility notes

- Designed for Godot 4.x and the project's Compatibility renderer.
- Faces forward along `-Z`; `Y` is up.
- Uses built-in mesh resources; no external texture files are required.
- This is a visual blockout, not a production character: no skeleton, skinning, animation clips, collision, or gameplay controller.
- The wing shapes are deliberately simple blockout geometry; they are not yet a sculpted membrane silhouette.

## Verification status

- Scene text and resources committed to the repository.
- Local Godot executable was not available in the current working environment, so no local engine import or visual runtime test is claimed.
- The repository's Godot 4.3 CI workflow is the next verification step. The scene has not yet been marked as tested in-engine.

## Safe integration plan

1. Import/parse this scene with the project's Godot 4.3 CI.
2. Open it in the editor and inspect silhouette, material appearance, and scale.
3. Compare against the current procedural hero from the gameplay camera.
4. Only replace the main-scene hero after visual and movement checks; keep the current player collision and movement controller independent of the render model.