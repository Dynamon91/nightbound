# Nightbound — Audio implementation plan

This document tracks the real music implementation separately from the visual prototype. A track marked “planned” is not an audio asset and must not be counted as playable content.

## Requirements

- Every playable level gets its own original theme; do not reuse a realm theme for multiple levels as a shortcut.
- Every boss gets a separate original boss theme, including bosses inside an existing level.
- Standard level target: 4–7 minutes. Boss target: 4–6 minutes. Longer tracks or layered stems are welcome when a level needs them.
- Compose for a musically intentional, seamless loop. Test the actual exported asset at the loop boundary; enabling a format's loop flag alone does not guarantee a seamless seam.
- Use several evolving sections, rhythmic variation, fills and optional intensity layers so exploration does not feel like a short phrase repeating.
- The requested Stewart Copeland inspiration is limited to high-level qualities: energetic syncopation, nimble percussion, unusual accents and interlocking rhythmic parts. Do not copy melodies, riffs, arrangements, recordings or recognizable passages.
- Use original or properly licensed assets only. Keep source sessions and license/provenance notes with the audio source files.

## Runtime foundation

`scripts/audio_director.gd` provides a small two-player music director with crossfades and track IDs. `scripts/main.gd` requests the Moonlit Valley theme at startup and requests the Veilwood theme after the realm transition. Missing assets fail safely; they are not synthesized or silently substituted.

Expected asset paths:

| Track ID | Asset path | Target |
|---|---|---|
| `moonlit_valley_level_1` | `res://audio/music/moonlit_valley_level_1.ogg` | 4–6 min |
| `moonlit_valley_boss_1` | `res://audio/music/moonlit_valley_boss_1.ogg` | 4–6 min |
| `veilwood_level_2` | `res://audio/music/veilwood_level_2.ogg` | 5–7 min |
| `veilwood_boss_2` | `res://audio/music/veilwood_boss_2.ogg` | 4–6 min |

## Acceptance checklist

- [ ] Add the original Moonlit Valley level theme.
- [ ] Add the dedicated Moonlit Valley boss theme.
- [ ] Add the original Veilwood level theme.
- [ ] Add the dedicated Veilwood boss theme.
- [ ] Check each track's exact duration and loop boundary in-game.
- [ ] Verify crossfades on realm entry and during save/load/scene restarts.
- [ ] Add music state/volume controls and ensure effects do not get routed through the music player.
- [ ] Expand this inventory whenever a playable level or boss is added; do not mark it complete until the matching track is present and tested.

## Current status

The routing/crossfade script is an initial integration foundation only. The four listed tracks are still planned and absent. No completed soundtrack is claimed.
