# Nightbound — Milestones & Mockup-Fidelity Progress

This is the project's working implementation roadmap. Percentages are **development estimates for the prototype's visual/asset implementation**, not measured completion percentages and not a claim that the full game is finished.

## Primary milestone — Reach the generated mockup's visual quality

**Current overall mockup-fidelity implementation: 55%**

The goal is an original, polished colourful 3D platforming world: a memorable bat protagonist, strong silhouettes, rich materials, layered environments, lighting, landmarks and substantial exploration spaces. The mockup is a visual quality target, not a claim that the game should copy Spyro.

### Art / model implementation

| Area | Progress | Target |
|---|---:|---|
| Original bat protagonist model | 58% | Recognisable, expressive, polished 3D hero with clean silhouette, wings, face and animation-ready proportions |
| Hero materials / eyes / wing detail | 53% | Cohesive stylized materials, readable eyes and membrane detail at gameplay distance |
| Terrain and cliffs | 48% | Layered stylized ground, cliffs, ledges and natural shapes rather than placeholder boxes |
| Rocks / props | 52% | Reusable stylized rock, crystal, ruin and environmental prop families |
| Vegetation | 49% | Distinct tree, grass, shrub and magical-forest families with controlled repetition |
| Crystals / collectibles | 65% | Consistent collectible language, glow, placement and feedback |
| Lighting / atmosphere | 65% | Moonlight, fog/depth, warm-vs-cool contrast and readable magical accents |
| Landmark quality | 62% | Large silhouettes visible across the level to support navigation |
| Veilwood environment | 60% | Distinct bioluminescent forest identity with layered traversal spaces |
| Moonlit Valley environment | 51% | Stronger authored scenery replacing generic prototype geometry |

### Platforming / level implementation

| Area | Progress | Target |
|---|---:|---|
| 3D movement / camera | 70% | Responsive third-person movement with polished camera behaviour |
| Jump + glide | 65% | Reliable aerial traversal and readable glide routes |
| Ability-gated exploration | 55% | Abilities open shortcuts, secrets and revisited routes |
| Collectible routes | 60% | Main path + risky detours + hidden optional paths |
| Realm transition | 65% | Seamless-feeling gate/realm progression |
| Large level structure | 44% | Broad interconnected areas with vertical layers, caves, alcoves and multiple routes |
| Secrets / optional challenges | 36% | Exploration rewards and revisitation loops |
| Enemy / encounter variety | 15% | Distinct enemies and encounters integrated into exploration |
| Boss / major set pieces | 0% | Not yet implemented/verified |

## Audio / music milestone

Implemented in code: `scripts/audio_director.gd` provides two-player crossfades, track IDs for the first two level themes and boss themes, safe missing-asset handling, and loop flags for Ogg Vorbis/WAV. `scripts/main.gd` requests the Moonlit Valley theme at startup and switches to the Veilwood theme on realm transition. Because the actual audio assets do not exist yet, this is integration scaffolding—not finished or audible soundtrack content. The latest code also resynchronizes the requested realm theme after loading a save. The first runtime verification must check Godot parsing, warnings, playback, transitions and loop seams after tracks are added.

**Music system integration: 20%** — an initial realm-aware routing/crossfade script is wired into gameplay. **Composition design: 25%** — four original score blueprints now define the opening level and boss themes. **Original rendered music content: 0%** — no final audio tracks have been rendered or added.

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

### Current planned soundtrack map

| Gameplay area | Music status | Composition target |
|---|---|---|
| Moonlit Valley — Level 1 | Planned | 4–6 min original exploration theme |
| Moonlit Valley — Boss 1 | Planned | 4–6 min original boss theme |
| Veilwood — Level 2 | Planned | 5–7 min original exploration theme |
| Veilwood — Boss 2 | Planned | 4–6 min original boss theme |
| Future Level N | Required | Unique theme before level is marked audio-complete |
| Future Boss N | Required | Unique boss theme before boss is marked audio-complete |

### Music quality rules

- Music should be **long**, with several evolving sections rather than a short repeating phrase.
- The loop point must feel musically intentional and effectively seamless.
- Rhythmic motion should remain interesting during long exploration sessions without becoming exhausting.
- Percussion can be agile, syncopated and intricate, drawing on the requested Copeland-inspired rhythmic spirit, but the compositions must remain original Nightbound works.
- Realm themes should have identifiable motifs while supporting exploration and discovery.
- Heart-Tree and major discoveries should preferably add or intensify layers instead of hard-cutting to unrelated music.
- Final audio must use original or properly licensed material; no copyrighted recordings should be bundled as game assets.

## Latest visual pass — grass silhouettes and wind motion

- Added low-poly, crossed-blade grass tufts to both Moonlit Valley and Veilwood, with palette changes between realms and exclusions around key routes.
- Added subtle phase-offset wind sway to the tuft meshes so the ground layer has motion rather than reading as static decoration.
- CI workflow for the grass silhouette pass completed successfully; the new wind-animation commit is queued and still requires its own CI result before being considered verified.

## Visual implementation gates

### Gate A — Hero model
- [x] Recognisable bat silhouette
- [x] Wings, face, ears and feet represented in the running scene
- [x] First face-material pass: emissive violet eyes with tiny catchlights, plus fine contrasting wing ribs
- [ ] Polished hero proportions and authored surface details
- [x] Added first-pass nose, cheek accents, inner-ear color and chest-fur tufts (needs screenshot review)
- [ ] Animation-quality wing/flight presentation
- [x] Procedural wing-beat animation for idle, falling and gliding (initial pass; needs visual polish in gameplay capture)

### Gate B — Environment
- [x] Distinct Moonlit Valley and Veilwood identities
- [x] Layered props, crystals, vegetation and landmarks
- [x] First authored grass-tuft pass in both realms to soften flat ground silhouettes
- [x] Veilwood arrival arch, moonstone trail and Heart-Tree landmark
- [ ] Replace remaining obvious primitive forms with authored meshes
- [ ] Add multiple authored terrain/cliff silhouettes and prop variants

### Gate C — Mockup comparison
- [x] Real running-game screenshots are produced by CI
- [ ] Gameplay screenshot visibly demonstrates the target density and polish
- [ ] Hero, terrain, materials, vegetation and lighting read as one cohesive art direction
- [ ] Repeat comparison pass until no major generic-placeholder area dominates the screenshot

## Definition of “mockup-like”

The milestone is considered visually reached only when the running game—not merely concept art—has:

- a polished original bat model that remains readable in gameplay screenshots;
- terrain with authored shapes, materials and silhouettes;
- multiple environmental asset families with controlled variation;
- atmospheric lighting and magical effects that reinforce the art direction;
- landmarks and composition comparable in visual density to the target mockup;
- levels that feel like substantial 3D adventure spaces rather than short test rooms;
- gameplay screenshots that visibly demonstrate the improvements.

## Next art pass

1. Replace the most obvious primitive terrain shapes with authored cliff/rock forms.
2. Improve the bat's proportions, face and wing presentation; procedural wing beats, emissive eyes/catchlights and fine membrane ribs are implemented as first passes.
3. Expand reusable vegetation and prop variants; the first low-poly grass-tuft pass now adds varied silhouettes to both realms.
4. Add stronger material variation to ground, stone and magical objects.
5. Add the original level/boss audio assets and verify the music director's crossfade and loop behaviour.
6. Create original long-form themes for **every playable level and every boss**, not just each realm.
7. Re-capture real gameplay screenshots and compare them against the mockup.
8. Iterate until the screenshot—not the design document—shows the intended quality.

## Important distinction

The generated mockups in `reference/` are **visual targets**. They are not gameplay screenshots. The project must not claim mockup fidelity has been achieved until the corresponding visual work exists in the running build and has been verified.
