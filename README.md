# Nightbound 🦇

Nightbound is an original **3D third-person exploration-platformer prototype** starring a small fantasy bat. The project is inspired by the exploration, jumping and collectible loop of classic 3D platformers; the protagonist remains a bat.

## Implemented in the current repository

- Third-person bat character and follow camera
- A small 3D valley with collision-backed ground and raised platforms
- Bridge, trees and a realm-gate landmark
- Collectible crystals and a HUD counter
- Echosense pulse that temporarily reveals hidden relics
- Jump and airborne glide control
- Burst movement and a crystal-gated Shadow Dash
- Local save/load of collected crystals and player position
- Moonlit environment lighting and a purple glow near the realm gate
- Veilwood realm with Moonseed collection objective, Heart-Tree reward, animated wisps and a rune-lit arrival trail

This is an early prototype. Larger features such as a complete multi-level campaign, finished boss encounter, checkpoints, and quest chains are **not yet verified as implemented in the current main-branch source**.

## Level design direction

Nightbound's levels must be substantial, expansive 3D adventure spaces—not short, narrow stages. The target is the sense of scale and discovery found in classic Spyro the Dragon levels: broad areas to roam, branching routes, vertical platforms and gliding paths, hidden caves and alcoves, optional challenges, plentiful collectibles, and secrets that reward revisiting areas after unlocking abilities. Each realm should feel like a memorable place with multiple connected sub-areas and meaningful exploration time. Keep the protagonist an original fantasy bat; Spyro is a reference for level structure and gameplay feel, not for replacing Nightbound's character or copying its worlds.

## Mockup-fidelity milestone

The project now tracks a dedicated **Mockup-Fidelity Implementation** milestone for the models, terrain, props, vegetation, lighting and level-art work needed to make the running game visually approach the generated mockup. The current development estimate is **42%** for this visual/asset milestone. See [`MILESTONES.md`](MILESTONES.md) for the detailed per-area progress and acceptance criteria.

The percentage is a planning estimate, not a measured visual score. The milestone is only considered reached when the running game itself demonstrates the target quality in verified gameplay screenshots.

## Controls

- **WASD** — move
- **Space** — jump; hold while airborne to glide
- **F** — burst
- **E** — Echosense
- **Shift** — Shadow Dash (unlocks after collecting 8 crystals)
- **P** — save
- **O** — load

## Run

1. Install Godot 4.x from the [official download page](https://godotengine.org/download/).
2. Open this folder in Godot Project Manager.
3. Run the main scene.

## Verification

The GitHub Actions workflow imports/parses the project and launches the main scene headlessly for 120 frames. This confirms a basic automated startup check; it does **not** replace interactive visual testing or prove every mechanic works as intended.

The preview image supplied separately is concept art, not a screenshot captured from a running build.

## Mockups and inspiration archive

See [`reference/MOCKUPS_AND_INSPIRATION.md`](reference/MOCKUPS_AND_INSPIRATION.md) for the visual direction archive, current mockup pointer, and Spyro reference links used to study classic 3D platformer exploration. Third-party references are linked for research; they are not project assets to copy. Concept art and actual gameplay screenshots are kept clearly distinguished.
