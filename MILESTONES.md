# Nightbound — Milestones & Mockup-Fidelity Progress

This is the project's working implementation roadmap. Percentages are **development estimates for the prototype's visual/asset implementation**, not measured completion percentages and not a claim that the full game is finished.

## Primary milestone — Reach the generated mockup's visual quality

**Current overall mockup-fidelity implementation: 57%**

The goal is an original, polished colourful 3D platforming world: a memorable bat protagonist, strong silhouettes, rich materials, layered environments, lighting, landmarks and substantial exploration spaces. The mockup is a visual quality target, not a claim that the game should copy Spyro.

### Art / model implementation

| Area | Progress | Target |
|---|---:|---|
| Original bat protagonist model | 59% | Recognisable, expressive, polished 3D hero with clean silhouette, wings, face and animation-ready proportions |
| Hero materials / eyes / wing detail | 53% | Cohesive stylized materials, readable eyes and membrane detail at gameplay distance |
| Terrain and cliffs | 48% | Layered stylized ground, cliffs, ledges and natural shapes rather than placeholder boxes |
| Rocks / props | 52% | Reusable stylized rock, crystal, ruin and environmental prop families |
| Vegetation | 56% | Distinct tree, grass, shrub and magical-forest families with controlled repetition |
| Crystals / collectibles | 65% | Consistent collectible language, glow, placement and feedback |
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

## Latest art pass — layered forest silhouettes

- Added a reusable stylized tree prop with a tapered trunk, faceted canopy and a small emissive magical-light accent.
- Moonlit Valley now has a second layer of trees around its play spaces so the background no longer reads as an empty green plane surrounded only by cliffs.
- Veilwood now has its own darker purple forest silhouettes, deliberately distinct from the Valley's greener tree palette.
- This is still placeholder-quality geometry compared with the final mockup target; the next art pass should replace these primitive tree forms with authored low-poly assets and richer material breakup.
- Commit: `84e873cdc4941e6a0fdc1f6f4a3739a622b77b46`.

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
