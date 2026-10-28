# Nightbound — Milestones & Mockup-Fidelity Progress

This is the project's working implementation roadmap. Percentages are **development estimates for the prototype's visual/asset implementation**, not measured completion percentages and not a claim that the full game is finished.

## Primary milestone — Reach the generated mockup's visual quality

**Current overall mockup-fidelity implementation: 48%**

The goal is an original, polished colourful 3D platforming world: a memorable bat protagonist, strong silhouettes, rich materials, layered environments, lighting, landmarks and substantial exploration spaces. The mockup is a visual quality target, not a claim that the game should copy Spyro.

### Art / model implementation

| Area | Progress | Target |
|---|---:|---|
| Original bat protagonist model | 48% | Recognisable, expressive, polished 3D hero with clean silhouette, wings, face and animation-ready proportions |
| Hero materials / eyes / wing detail | 40% | Cohesive stylized materials, readable eyes and membrane detail at gameplay distance |
| Terrain and cliffs | 44% | Layered stylized ground, cliffs, ledges and natural shapes rather than placeholder boxes |
| Rocks / props | 48% | Reusable stylized rock, crystal, ruin and environmental prop families |
| Vegetation | 40% | Distinct tree, grass, shrub and magical-forest families with controlled repetition |
| Crystals / collectibles | 62% | Consistent collectible language, glow, placement and feedback |
| Lighting / atmosphere | 62% | Moonlight, fog/depth, warm-vs-cool contrast and readable magical accents |
| Landmark quality | 58% | Large silhouettes visible across the level to support navigation |
| Veilwood environment | 55% | Distinct bioluminescent forest identity with layered traversal spaces |
| Moonlit Valley environment | 47% | Stronger authored scenery replacing generic prototype geometry |

### Platforming / level implementation

| Area | Progress | Target |
|---|---:|---|
| 3D movement / camera | 70% | Responsive third-person movement with polished camera behaviour |
| Jump + glide | 65% | Reliable aerial traversal and readable glide routes |
| Ability-gated exploration | 55% | Abilities open shortcuts, secrets and revisited routes |
| Collectible routes | 60% | Main path + risky detours + hidden optional paths |
| Realm transition | 65% | Seamless-feeling gate/realm progression |
| Large level structure | 40% | Broad interconnected areas with vertical layers, caves, alcoves and multiple routes |
| Secrets / optional challenges | 32% | Exploration rewards and revisitation loops |
| Enemy / encounter variety | 15% | Distinct enemies and encounters integrated into exploration |
| Boss / major set pieces | 0% | Not yet implemented/verified |

## Audio / music milestone

**Current music implementation: 10%** — direction and integration requirements are defined; final original tracks are not yet implemented.

Nightbound's soundtrack must use **long-form original compositions built for excellent seamless looping**. The intended musical character takes high-level inspiration from the energetic, syncopated, rhythmically intricate and highly percussive spirit associated with **Stewart Copeland**, while remaining distinctly original: no copied melodies, riffs, arrangements, recordings or other protected elements.

| Area | Progress | Target |
|---|---:|---|
| Music system / realm track routing | 15% | Stable music bus, realm-aware tracks and smooth transitions |
| Moonlit Valley theme | 0% | Original 4–6 minute evolving exploration composition with seamless loop |
| Veilwood theme | 0% | Original 5–7 minute evolving exploration composition with seamless loop |
| Realm Gate transition theme | 0% | Original 2–3 minute loopable transition/arrival piece |
| Dynamic intensity layers | 0% | Exploration/discovery/Heart-Tree layers that blend without abrupt resets |
| Loop verification | 0% | Boundary tested in the running game with no audible click or restart feeling |

### Music quality rules

- Music should be **long**, with several evolving sections rather than a short repeating phrase.
- The loop point must feel musically intentional and effectively seamless.
- Rhythmic motion should remain interesting during long exploration sessions without becoming exhausting.
- Percussion can be agile, syncopated and intricate, drawing on the requested Copeland-inspired rhythmic spirit, but the compositions must remain original Nightbound works.
- Realm themes should have identifiable motifs while supporting exploration and discovery.
- Heart-Tree and major discoveries should preferably add or intensify layers instead of hard-cutting to unrelated music.
- Final audio must use original or properly licensed material; no copyrighted recordings should be bundled as game assets.

## Visual implementation gates

### Gate A — Hero model
- [x] Recognisable bat silhouette
- [x] Wings, face, ears and feet represented in the running scene
- [ ] Polished hero proportions and authored surface details
- [ ] Animation-quality wing/flight presentation

### Gate B — Environment
- [x] Distinct Moonlit Valley and Veilwood identities
- [x] Layered props, crystals, vegetation and landmarks
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
2. Improve the bat's proportions, face and wing presentation.
3. Build reusable vegetation and prop variants.
4. Add stronger material variation to ground, stone and magical objects.
5. Implement the long-form music system and realm-aware looping.
6. Create original long-form realm themes with excellent seamless loops.
7. Re-capture real gameplay screenshots and compare them against the mockup.
8. Iterate until the screenshot—not the design document—shows the intended quality.

## Important distinction

The generated mockups in `reference/` are **visual targets**. They are not gameplay screenshots. The project must not claim mockup fidelity has been achieved until the corresponding visual work exists in the running build and has been verified.
