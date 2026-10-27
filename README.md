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

This is an early prototype. Larger features such as a complete multi-level campaign, finished boss encounter, checkpoints, and quest chains are **not yet verified as implemented in the current main-branch source**.

## Level design direction

Nightbound's levels must be substantial, expansive 3D adventure spaces—not short, narrow stages. The target is the sense of scale and discovery found in classic Spyro the Dragon levels: broad areas to roam, branching routes, vertical platforms and gliding paths, hidden caves and alcoves, optional challenges, plentiful collectibles, and secrets that reward revisiting areas after unlocking abilities. Each realm should feel like a memorable place with multiple connected sub-areas and meaningful exploration time. Keep the protagonist an original fantasy bat; Spyro is a reference for level structure and gameplay feel, not for replacing Nightbound's character or copying its worlds.

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
