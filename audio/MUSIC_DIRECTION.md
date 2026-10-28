# Nightbound — Music Direction

## Core requirement

Nightbound should have **long-form original music designed for seamless looping**. Music is part of the level identity, not a short placeholder jingle.

The soundtrack should explicitly draw on the **broad musical character of Stewart Copeland's original Spyro the Dragon score**: playful, mischievous fantasy-adventure energy; punchy and nimble percussion; syncopated, interlocking rhythmic parts; distinctive bass movement; bright, quirky timbres; and themes whose instrumentation and groove reflect each place. Aim for that sense of lively exploration and characterful world-specific scoring—not a generic orchestral fantasy soundtrack. Translate those high-level traits into Nightbound's own nocturnal, bat-led identity. All melodies, motifs, riffs, arrangements, sound design and recordings must remain original; do not recreate or closely imitate any Spyro cue.

## Realm themes

### Moonlit Valley — `moonlit_valley`
- Target length: 4–6 minutes before a seamless loop.
- Mood: nocturnal adventure, playful mystery, forward motion.
- Rhythm: syncopated percussion, agile accents and changing subdivisions.
- Palette: hand percussion, tight kit, mallet/plucked textures, bass movement and airy nocturnal layers.
- Arrangement should evolve through several sections so the loop does not feel repetitive.

### Veilwood — `veilwood`
- Target length: 5–7 minutes before a seamless loop.
- Mood: enchanted forest, discovery, movement between calm and energetic traversal.
- Rhythm: intricate interlocking percussion with lighter passages and rising accents.
- Palette: organic percussion, tuned percussion, low pulse, shimmering magical textures and restrained melodic motifs.
- The Heart-Tree area should have an optional intensified musical layer rather than abruptly switching tracks.

### Realm Gate — `realm_gate`
- Target length: 2–3 minutes, designed as a loopable transition/arrival piece.
- A rhythmic motif should bridge the two realm themes.

## Loop quality requirements

- Loops must be sample-accurate or otherwise crossfade-free at the loop boundary.
- Musical phrases should resolve into the beginning naturally; avoid obvious hard resets.
- Each long track should contain multiple evolving sections and controlled variation.
- Avoid constant full-intensity instrumentation: reserve layers for exploration, discoveries and landmarks.
- No copyrighted recordings or unlicensed samples.
- Final game assets should use original compositions and appropriately licensed/generated source material.

## Implementation plan

1. Build the soundtrack system with named realm tracks and a stable music bus.
2. Support seamless looping and volume transitions between exploration states.
3. Add optional intensity layers for discoveries and the Heart-Tree.
4. Create/export original long-form tracks after the gameplay music system is verified.
5. Verify every final loop by listening across the boundary in the running game.

## Acceptance criteria

The music milestone is complete only when each major realm has a long-form original track, the loop boundary is inaudible during continuous gameplay, and the soundtrack supports exploration without becoming monotonous.
