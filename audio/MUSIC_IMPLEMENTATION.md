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

## Next production step

Create original long-form stems for Moonlit Valley and its first boss theme, integrate them into the Godot music bus, and use those as the production template for every subsequent level and boss before marking the composition milestone above 20%.
