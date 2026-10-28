# Nightbound — Music Implementation

## Current milestone

**Audio system foundation: 20%**

This is deliberately separate from the final music-composition percentage. The repository currently has the musical direction documented, but no final audio recordings are claimed as complete until they are actually created, imported and heard in the running game.

## In-game architecture target

- One persistent music bus.
- Named realm states: `moonlit_valley`, `veilwood`, `realm_gate`.
- **Every playable level gets its own original theme.** A level must never silently reuse another level's main theme merely for convenience.
- **Every boss encounter gets its own original boss theme**, with enough development to support a full fight rather than a short stinger.
- Seamless loop points with no audible reset.
- Crossfades between level, realm and boss states rather than hard cuts.
- Optional intensity layers for discoveries, major landmarks and the Heart-Tree.
- Exploration music remains active through long platforming sections.
- Music volume and effects remain independently controllable.

## Per-level and boss music rule

The final soundtrack is organized around the game's actual level structure. Each level receives a distinct musical identity based on its environment, traversal style and story role. Bosses are treated as separate musical identities even when they occur inside an existing level.

Boss transitions should preserve musical continuity: the exploration theme can fade or hand off into the boss theme, but the boss track itself must be substantial and memorable. Returning to exploration should use a clean musical transition rather than restarting the level theme unnecessarily.

**No final soundtrack track may be marked complete until the corresponding level/boss is playable and its music has been heard in-game.**

## Composition targets

| Track | Target duration | Structure |
|---|---:|---|
| Each standard level theme | 4–7 min target | Intro → exploration A → variation → exploration B → development/bridge → return |
| Each boss theme | 4–6 min target | Entrance → main combat A → variation → escalation → climax → combat return |
| Realm Gate / transition theme | 2–3 min | Arrival motif → transition development → seamless return |
| Major landmark / discovery layer | 45–90 sec layered material | Designed to overlay or crossfade without breaking the underlying level theme |

These are minimum production targets, not a requirement that every track be exactly the same length. Especially long levels can receive longer themes or additional musical sections.

## Musical identity

Use only broad, non-infringing inspiration from Stewart Copeland's rhythmic qualities: syncopation, energetic percussion, interlocking parts, unusual accents and dynamic movement. Nightbound melodies, riffs, arrangements, recordings and sound design must remain original.

Different levels should also have different instrumentation, tempo, harmonic color and rhythmic character so that the soundtrack communicates location and gameplay rather than sounding like one generic track reused everywhere.

## Acceptance test

A track is not marked complete merely because an audio file exists. It must play in the running game, sustain a long exploration session without becoming obviously repetitive, and pass a boundary test where the end connects naturally to the beginning.

For every level and boss, acceptance additionally requires:

1. A unique original theme is assigned to that gameplay section.
2. The track is long-form enough for the intended encounter.
3. The loop boundary is tested in-game and has no audible click, gap or obvious reset.
4. At least one meaningful musical variation occurs before the loop returns.
5. Boss music has a dedicated escalation/climax section suitable for the fight.
6. Crossfades/transitions do not abruptly restart the music when moving between exploration, boss and post-boss states.

## Level-by-level soundtrack plan

The following is a required production matrix, not a claim that the tracks already exist. New levels and bosses must be added here before their music is considered part of the finished soundtrack.

| Gameplay section | Music identity | Target | Status |
|---|---|---:|---|
| Moonlit Valley | Original nocturnal exploration theme | 4–7 min | Planned |
| Moonlit Valley — Boss | Dedicated combat theme | 4–6 min | Planned |
| Veilwood | Original bioluminescent forest theme | 5–7 min | Planned |
| Veilwood — Boss | Dedicated Heart-Tree/forest boss theme | 4–6 min | Planned |
| Realm Gate | Original transition/threshold theme | 2–3 min | Planned |
| Future Level 03 | Unique level theme | 4–7 min | Planned |
| Future Level 03 — Boss | Dedicated boss theme | 4–6 min | Planned |
| Future Level 04 | Unique level theme | 4–7 min | Planned |
| Future Level 04 — Boss | Dedicated boss theme | 4–6 min | Planned |
| Additional levels | One unique theme per level | 4–7 min | Planned |
| Additional bosses | One unique theme per boss | 4–6 min | Planned |

As the level roster grows, this table must grow with it. **“Per level + per boss” is a permanent soundtrack rule for the project.**

## Current composition work

`COMPOSITION_SKETCHES.md` now contains four original score blueprints: Moonlit Valley exploration, Veilwood exploration, Moonlit Valley boss, and Veilwood boss. Each specifies a distinct meter/rhythm, tempo, tonal palette, original motif, instrumentation, arrangement timeline and loop-return design. These are composition plans, **not rendered audio**; audio content remains 0% until recordings or synthesized audio assets are integrated and listened to in-game.

## Next production step

Render the first original Moonlit Valley theme into an Ogg Vorbis asset, import it into Godot, then verify playback, long-form development, loop seam and crossfade in a running build. Continue with each level and boss as a separate track.
