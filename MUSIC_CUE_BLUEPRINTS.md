# Nightbound — Original Music Cue Blueprints

This document turns the audio milestone into four composition-ready arrangements. These are production blueprints, not finished audio assets; none of the cues should be counted as playable soundtrack content until an original render is added and loop-tested in Godot.

## Shared musical identity

- **Core feel:** nocturnal adventure with forward momentum, playful rhythmic surprise, and a little danger around every corner.
- **Rhythmic language:** syncopated bass ostinatos, interlocking percussion, displaced accents, short asymmetric fills, and occasional bars that briefly thin out before the groove returns.
- **Originality boundary:** use broad qualities such as nimble percussion and intricate rhythmic interplay as inspiration. Do not reproduce identifiable melodies, riffs, arrangements, recordings, or signature passages from any existing composer or game.
- **Loop design:** compose each cue as a complete long-form arc, not a short loop padded to reach the target duration. The final phrase must resolve harmonically and rhythmically into the opening without a click, timing jump, abrupt reverb tail, or percussion discontinuity.
- **Implementation target:** 48 kHz stereo master; export Ogg Vorbis for runtime; keep lossless source renders, tempo maps, stem notes, and provenance alongside the project source.
- **Runtime behaviour:** the audio director may crossfade between cues, but each cue itself must have a tested seamless loop. Crossfading is not a substitute for loop editing.

## Cue 01 — Moonlit Valley (level)

**Runtime target:** 4:30–5:30  
**Tempo / meter:** 112 BPM, 4/4; occasional two-beat percussion fills create forward motion without changing the underlying pulse.  
**Harmony:** D Dorian centre with open fifths and a recurring upper-note motif; avoid a strongly resolved cadence until the final loop bar.

**Palette**
- Muted low tom and dry hand percussion as the rhythmic engine.
- Plucked, woody ostinato with alternating two- and three-note groupings.
- Warm bass pulses that answer rather than simply double the ostinato.
- Airy mallet tones, restrained glass harmonics, and a distant pad for moonlit scale.
- Sparse wing-like swishes and crystal chimes as optional gameplay stingers, not embedded in the music master.

**Long-form arrangement**
1. **0:00–0:35 — Arrival:** low drone, isolated plucks, and a light pulse; leave space for the player to orient.
2. **0:35–1:20 — Main path:** bass ostinato and dry percussion enter; introduce the primary original motif.
3. **1:20–2:05 — Discovery:** add a counter-rhythm and a brighter mallet answer; vary the motif rather than repeating it unchanged.
4. **2:05–2:50 — Elevated route:** increase syncopation and add a second percussion voice; keep the harmony open and exploratory.
5. **2:50–3:35 — Hidden alcove:** strip back the kick-like pulse, use a quieter register, and let resonant tones suggest discovery.
6. **3:35–4:25 — Return to route:** rebuild interlocking parts, with two short fills that differ in length and accent.
7. **4:25–end — Loop handoff:** return to the opening texture over a sustained shared harmonic bed; align transient timing and reverb tails so the end-to-start boundary is inaudible.

**Intensity layers:** base exploration; added mid percussion for elevated routes; added bass/percussion accents near the realm gate. Layers must remain in the same tempo and compatible harmonic frame.

## Cue 02 — Moonlit Valley (boss)

**Runtime target:** 4:00–5:00  
**Tempo / meter:** 132 BPM, 4/4, with a recurring three-beat accent cycle laid across the bar.  
**Harmony:** D minor with chromatic tension and brief suspended openings for attack windows.

**Palette**
- Tight low toms, metallic rim hits, and a syncopated bass ostinato.
- Short brass-like synth stabs and rough bowed textures made from original synthesis/sampling.
- A two-part rhythmic motif: one clipped phrase answered by a longer descending figure.
- Sparse high-register warning notes before major phrase changes.

**Long-form arrangement**
1. **0:00–0:25 — Threat reveal:** isolated low pulse and a two-note warning figure.
2. **0:25–1:10 — First exchange:** full groove, clipped motif, and bass counterline.
3. **1:10–1:55 — Pressure:** denser tom syncopation and a rising upper voice; avoid constant maximum loudness.
4. **1:55–2:35 — Vulnerability window:** pull back the bass and leave a clear rhythmic gap for gameplay feedback.
5. **2:35–3:25 — Second exchange:** return with a shifted accent pattern and a new counter-melody.
6. **3:25–4:10 — Final push:** layered percussion and descending sequence, with a short break before the return.
7. **Loop handoff:** preserve the tension bed and bass pulse across the boundary; do not use a final-hit cymbal or a one-shot that makes the loop seam obvious.

**Intensity layers:** standard encounter; high-pressure phase; vulnerability/transition layer. Gameplay state changes should not restart the music from bar one.

## Cue 03 — The Veilwood (level)

**Runtime target:** 5:00–6:30  
**Tempo / meter:** 98 BPM, 6/8, with occasional duple percussion accents for contrast.  
**Harmony:** A Aeolian with suspended seconds and a restrained raised-sixth colour in the brighter discovery section.

**Palette**
- Hollow wooden taps, seed-pod rattles, and soft low toms.
- Rounded plucked bass in a repeating but evolving pattern.
- Glassy mallets, breathy original synth tones, and delicate high-register counterpoint.
- A slow, irregular secondary pulse that makes the forest feel alive without obscuring platforming cues.

**Long-form arrangement**
1. **0:00–0:40 — Crossing the gate:** breathy pad, soft rattle, and a small motif shared between two timbres.
2. **0:40–1:30 — Luminous trail:** bass and low toms establish a gentle 6/8 roll.
3. **1:30–2:20 — Wisp grove:** introduce a floating counter-melody and brighter mallet response.
4. **2:20–3:10 — Deep canopy:** thin the high end, use a slower-moving bass variation, and add distant rhythmic echoes.
5. **3:10–4:05 — Moonseed route:** increase rhythmic interlock and introduce a new motif fragment.
6. **4:05–5:00 — Heart-Tree approach:** expand the harmonic register and layer the main motif in a warmer timbre.
7. **5:00–end — Return:** gradually remove the brightest layer and land on the same sustained harmonic bed as the opening.

**Intensity layers:** calm exploration; active traversal; near-objective glow. Keep the wisp accents musical and sparse so they do not compete with sound effects.

## Cue 04 — Veilwood (boss)

**Runtime target:** 4:00–5:30  
**Tempo / meter:** 124 BPM, 4/4, with a 3+3+2 accent grouping.  
**Harmony:** A minor with dissonant upper seconds resolving into open fifths during recovery windows.

**Palette**
- Deep toms, dry woodblocks, and a low syncopated pulse.
- Glass/metallic hits used as rhythmic punctuation rather than constant sparkle.
- A tense two-note ostinato against a longer, descending original line.
- A low drone that can persist under phase transitions without a hard restart.

**Long-form arrangement**
1. **0:00–0:30 — Awakening:** drone and distant, irregular taps.
2. **0:30–1:15 — First phase:** 3+3+2 groove, bass ostinato, and a compact motif.
3. **1:15–2:00 — Escalation:** add a second percussion layer and a counterline in a higher register.
4. **2:00–2:40 — Opening:** reduce rhythmic density and let open fifths create a readable recovery window.
5. **2:40–3:30 — Phase shift:** alter the accent pattern and invert the motif contour; avoid simply increasing volume.
6. **3:30–4:20 — Climax:** full interlocking percussion and the strongest bass movement.
7. **Loop handoff:** remove the climax fill before the boundary and transition to the opening drone with shared ambience and aligned pulse.

**Intensity layers:** phase one; phase two; recovery. All layers should be authored against one tempo map and checked for phase alignment.

## Production checklist

- [ ] Compose and render each cue as a distinct original piece at the target duration.
- [ ] Keep source sessions and provenance/licence notes with the source renders.
- [ ] Confirm exact duration, sample rate, channel count, clipping headroom, and file size.
- [ ] Listen to at least three consecutive loop cycles for each exported Ogg.
- [ ] Inspect and audition the exact end-to-start boundary, including reverb and delay tails.
- [ ] Test each track in Godot 4.3 using the real audio director and verify crossfades.
- [ ] Test scene reload/save-load and realm transitions without duplicate players or abrupt restarts.
- [ ] Only then update the soundtrack progress estimate and mark a cue as implemented.
