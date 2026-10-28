# Nightbound — Music Implementation

## Current milestone

**Audio system foundation: 20%**

This is deliberately separate from the final music-composition percentage. The repository currently has the musical direction documented, but no final audio recordings are claimed as complete until they are actually created, imported and heard in the running game.

## In-game architecture target

- One persistent music bus.
- Named realm states: `moonlit_valley`, `veilwood`, `realm_gate`.
- Seamless loop points with no audible reset.
- Crossfades between realm states rather than hard cuts.
- Optional intensity layer for discoveries and the Heart-Tree.
- Exploration music remains active through long platforming sections.
- Music volume and effects remain independently controllable.

## Composition targets

| Track | Target duration | Structure |
|---|---:|---|
| Moonlit Valley | 4–6 min | Intro → exploration A → variation → exploration B → bridge → return |
| Veilwood | 5–7 min | Quiet discovery → rhythmic exploration → growth → Heart-Tree variation → return |
| Realm Gate | 2–3 min | Arrival motif → transition development → seamless return |

## Musical identity

Use only broad, non-infringing inspiration from Stewart Copeland's rhythmic qualities: syncopation, energetic percussion, interlocking parts, unusual accents and dynamic movement. Nightbound melodies, riffs, arrangements, recordings and sound design must remain original.

## Acceptance test

A track is not marked complete merely because an audio file exists. It must play in the running game, sustain a long exploration session without becoming obviously repetitive, and pass a boundary test where the end connects naturally to the beginning.

## Next production step

Create original long-form stems for Moonlit Valley and integrate them into the Godot music bus before marking the composition milestone above 20%.
