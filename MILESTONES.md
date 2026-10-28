## Latest runtime verification — first nonblank gameplay capture

- Godot 4.3 strict CI passed on source commit 73a17c810feda23693bdd07506f59f1408bb8b74: editor import, 120-frame headless launch, window launch, screenshot capture and source packaging.
- Inspected the captured 1280×720 screenshot. It shows the actual in-game Moonlit Valley scene, HUD, bat character, crystals, route platforms and gate arch; it is not concept art. The old blank screenshot was traced to the GDScript parse errors now fixed.
- The world remains an early procedural prototype with primitive terrain/props and flat materials. The screenshot is a truthful starting point for the next art pass, not a claim that mockup fidelity is complete.
- Workflow and downloadable artifacts: https://github.com/Dynamon91/nightbound/actions/runs/40726069737

## Latest gameplay repair — main scene startup and hidden relics

- Added an explicit _ready() bootstrap to instantiate the audio director, restore save data before collectibles are created, and build the Valley, Veilwood, bat, camera and HUD.
- Fixed a GDScript parse blocker where the checkpoint variable collided with the checkpoint() builder function; the saved respawn vector is now named checkpoint_position.
- Reconnected P/O save-load controls. O reloads the scene so restored collectible IDs are applied during world construction.
- Implemented Echosense gameplay: E reveals up to five hidden relics with a warm emissive glow for five seconds; relic collection and IDs are persisted in the save file and shown in the HUD.
- An earlier CI screenshot was a blank frame, and its runtime log exposed the script parse error. After the checkpoint-name fix, the current strict Godot 4.3 workflow now passes and the 1280×720 gameplay capture visibly shows the bat, HUD, route geometry and landmarks. This verifies scene startup/rendering, not polished final art or interactive testing of every control.
- Commits: 08063a54a23bfc0476d4cb0ae0206baaa7dc48e0, 8c47fb97dc873354dee2071801998b051bf8d273, 2fe5640d04b20673406e684e623a7982e4c9da6c.

## Latest CI reliability pass — script errors now fail checks

- The Godot workflow now checks both editor-import and headless-runtime logs for GDScript parse/load errors instead of trusting a zero exit code alone.
- The visible-window launch also fails if the runtime log contains a script load error, preventing another blank gameplay screenshot from being accepted as healthy.
- Commit: 8f0988f602d2e6dc3b2659293e3c1f2f4925889d.

## Latest collectible polish — hovering crystals and Moonseeds

- Crystals, Moonshards and Moonseeds now gently bob and sway in place, with deterministic per-item phase offsets so nearby pickups do not move in lockstep.
- The effect uses each collectible mesh’s stored spawn position, so motion does not accumulate drift; emissive intensity now pulses softly with the same per-item phase offset.
- Visual feel and runtime performance still need in-game verification.
- Commits: `6b5a9e04dc0250bfbd7deb89bf59bafaf9eea08c`, `088b848438803597c875696f25ca4ebd92fc5d69`.

## Latest environment pass — drifting luminous motes

- Added 24 soft teal motes to the Moonlit Valley and 28 violet motes to the Veilwood. They float gently and rotate, with separate palettes to help distinguish the two realms.
- Motes are lightweight procedural spheres with emission; density, readability and performance still need in-game inspection.
- Commit: `c5adedde8603b8c8331cc39685692b11f12ecc13`.

## Latest animation pass — subtle life in the bat silhouette

- Added a restrained body bob, slight head counter-motion and a gentle tail sway, layered on top of the existing wing flap and body banking.
- This is code-level animation work; in-game feel and clipping still need runtime inspection.
- Commit: `f3307f5bc5149bb5bdeea53beddcb314e1312552`.

## Latest character-art pass — face and chest readability

- Added a compact muzzle, contrasting nose and chest bib to break up the single dark head/body silhouette.
- These details are procedural meshes; proportions still need visual inspection in a live game camera.
- Commit: `803c33043fb4e803156bce2d16ac10f2f509cff3`.

# Nightbound — Milestones & Mockup-Fidelity Progress

This is the project's working implementation roadmap. Percentages are **development estimates for the prototype's visual/asset implementation**, not measured completion percentages and not a claim that the full game is finished.

## Primary milestone — Reach the generated mockup's visual quality

**Current overall mockup-fidelity implementation: 63%**

The goal is an original, polished colourful 3D platforming world: a memorable bat protagonist, strong silhouettes, rich materials, layered environments, lighting, landmarks and substantial exploration spaces. The mockup is a visual quality target, not a claim that the game should copy Spyro.

### Art / model implementation

| Area | Progress | Target |
|---|---:|---|
| Original bat protagonist model | 59% | Recognisable, expressive, polished 3D hero with clean silhouette, wings, face and animation-ready proportions |
| Hero materials / eyes / wing detail | 53% | Cohesive stylized materials, readable eyes and membrane detail at gameplay distance |
| Terrain and cliffs | 51% | Layered stylized ground, cliffs, ledges and natural shapes rather than placeholder boxes |
| Rocks / props | 56% | Reusable stylized rock, crystal, ruin and environmental prop families |
| Vegetation | 56% | Distinct tree, grass, shrub and magical-forest families with controlled repetition |
| Crystals / collectibles | 68% | Consistent collectible language, glow, placement and feedback |
| Lighting / atmosphere | 65% | Moonlight, fog/depth, warm-vs-cool contrast and readable magical accents |
| Landmark quality | 62% | Large silhouettes visible across the level to support navigation |
| Veilwood environment | 62% | Distinct bioluminescent forest identity with layered traversal spaces |
| Moonlit Valley environment | 54% | Stronger authored scenery replacing generic prototype geometry |

### Platforming / level implementation

| Area | Progress | Target |
|---|---:|---|
| 3D movement / camera | 71% | Responsive third-person movement with polished camera behaviour |
| Jump + glide | 67% | Reliable aerial traversal, readable glide routes and a live on-screen stamina meter |
| Ability-gated exploration | 55% | Abilities open shortcuts, secrets and revisited routes |
| Collectible routes | 64% | Main path + risky detours + hidden optional paths, including optional elevated Moonshard caches |
| Realm transition | 65% | Seamless-feeling gate/realm progression |
| Large level structure | 44% | Broad interconnected areas with vertical layers, caves, alcoves and multiple routes |
| Secrets / optional challenges | 42% | Exploration rewards and revisitation loops, with three persistent optional Moonshards on raised Valley routes |
| Enemy / encounter variety | 15% | Distinct enemies and encounters integrated into exploration |
| Boss / major set pieces | 0% | Not yet implemented/verified |

## Latest art pass — bat silhouette refinement\n\n- Added tapered ears with inner accents, three visible membrane ribs per wing, small feet, a tapered tail tuft and white eye glints. Existing wing nodes remain animated by the current flight/idle animation loop.\n- This is a procedural mesh-detail pass, not a final sculpted hero model; proportions and wing deformation still need an in-game visual check.\n- Commit: `adac1176238e1c51eab3b3f9432534a9409ec6fd`.\n\n## Previous art pass — layered faceted cliff formations\n\n- Reworked cliff clusters from repeated round blobs into irregular low-poly boulders with varied scale, rotation and a controlled cool stone palette.\n- Added broken horizontal ledges to create a more layered cliff silhouette while retaining the existing broad cliff placements. These are visual mesh changes; collision/runtime appearance still need an in-game check.\n- Commit: `f7958982e279dcdaf355125559210765e6697d54`.\n\n## Previous art pass — layered forest silhouettes

- Added a reusable stylized tree prop with a tapered trunk, faceted canopy and a small emissive magical-light accent.
- Moonlit Valley now has a second layer of trees around its play spaces so the background no longer reads as an empty green plane surrounded only by cliffs.
- Veilwood now has its own darker purple forest silhouettes, deliberately distinct from the Valley's greener tree palette.
- This is still placeholder-quality geometry compared with the final mockup target; the next art pass should replace these primitive tree forms with authored low-poly assets and richer material breakup.
- Commit: `84e873cdc4941e6a0fdc1f6f4a3739a622b77b46`.

## Latest art-direction pass — model and environment quality gate

- Added `ART_STYLE_GUIDE.md` as the working specification for the visual upgrade from prototype primitives to authored-looking assets.
- The guide defines concrete targets for the bat silhouette, wing membranes, terrain/cliff silhouettes, rock families, vegetation clustering, collectible readability, landmarks, camera framing and realm-specific lighting.
- It also defines a screenshot-quality gate: foreground/midground/background layering, readable traversal, distinct realm identity and no dependence on HUD labels to recognize the hero.
- This is a production guide, not a claim that these final assets already exist.
- Commit: `24e9a999e8357bf06e591f74912ca32c365c1b23`.

## Latest gameplay pass — persistence and checkpoints

- Fixed collectible persistence: crystals, Moonshards and Moonseeds now receive stable IDs, are recorded in the save file, and are omitted when the game rebuilds the world after loading.
- Fixed checkpoint persistence: entering a new checkpoint now immediately saves the new respawn position instead of only changing it in memory.

## Audio / music milestone

Implemented in code: `scripts/audio_director.gd` provides two-player crossfades, track IDs for the first two level themes and boss themes, safe missing-asset handling, and loop flags for Ogg Vorbis/WAV. `scripts/main.gd` requests the Moonlit Valley theme at startup and switches to the Veilwood theme on realm transition. Because the actual audio assets do not exist yet, this is integration scaffolding—not finished or audible soundtrack content.

**Music system + procedural synthesis: 42%** — realm-aware routing, crossfades, automatic 16-bar section progression and a first-pass original procedural synthesizer are present in code; continuous oscillator phases have been added to reduce loop-boundary discontinuities. **Composition design: 25%** — four original score blueprints define the first two level and boss themes. **Final authored/rendered soundtrack assets: 0%** — no polished final Ogg/WAV tracks have been added. CI and Godot runtime playback/listening tests remain required before calling the music system verified.

Nightbound's soundtrack must use **long-form original compositions built for excellent seamless looping**. The intended musical character takes high-level inspiration from the energetic, syncopated, rhythmically intricate and highly percussive spirit associated with **Stewart Copeland**, while remaining distinctly original: no copied melodies, riffs, arrangements, recordings or other protected elements.

### Per-level soundtrack rule

The soundtrack is organized by the **actual playable level structure**, not merely by broad realms. Every substantial playable level receives its own original theme. Every boss receives a separate original boss theme, even when the boss is inside an existing level. No level may reuse another level's main theme just for convenience.

| Track class | Target duration | Required identity |
|---|---:|---|
| Each standard level | 4–7 min target | Unique motif, instrumentation, rhythm and evolving sections; seamless loop |
| Each boss | 4–6 min target | Dedicated combat identity, escalation, variation and climax; seamless loop |
| Realm Gate / transition | 2–3 min | Arrival motif and transition development |
| Major landmark / discovery layer | 45–90 sec | Optional layer that can overlay/crossfade without breaking the level theme |

For long levels, tracks may exceed the target duration or use additional sections/stems. The goal is to keep exploration fresh rather than force short repetition.

## Latest audio pass — automatic long-loop sections

- The audio director now advances the procedural score every 16 bars using each track's own BPM and meter rather than leaving the section selector dormant.
- The eight-section cycle is reset when a new level/boss theme starts and remains compatible with the existing two-player crossfade system.
- This is intended to make the 4–7 minute target loops feel like evolving compositions instead of short phrases repeated unchanged.

## Latest traversal pass — controlled glide

- Improved the glide's descent cap from `-3.0` to `-2.4` and reduced the extra downward acceleration while gliding, making the descent more forgiving.
- Added stronger directional air steering while gliding and gentle horizontal drag when no direction is held, while retaining the finite 2.8-second stamina limit and ground-based refill.

## Latest hero animation pass — flight lean

- Added a subtle torso pitch for glide/fall states, banking that responds to horizontal velocity, and a small body bob; the head counter-leans slightly to keep the face readable.
- This layers onto the existing wing-beat animation rather than replacing it.

## Latest recovery pass — fall reset and luminous checkpoints

- Added a safety recovery when the player falls below the playable world: position resets to the current saved checkpoint, velocity is cleared, and glide stamina is reset.
- Added luminous checkpoint rings at three Moonlit Valley perches and two Veilwood route landmarks.
- The newest pass now persists both checkpoint position and collectible identity across saves.
