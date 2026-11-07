# Nightbound — animated Godot 4 title menu

This milestone introduces a **native, interactive Godot 4 title menu**, as distinct from the earlier browser-based demo.

## Runtime
- Scene: `res://scenes/title_menu.tscn` (the project startup scene).
- Script: `res://scripts/title_menu.gd`.
- Artwork: reuses `backups/2026-10-31/images/nightbound_title_background.png` already tracked by this repository.
- Intro: timed, skippable title overlay followed by the interactive menu (not a real-time 3D flyover).
- Background: slight zoom/rotation, moonlight modulation and 22 drifting motes; motion can be disabled in Options.
- Buttons: New Game, Continue, Load, Options, Extras, Exit.
- Continue uses the existing `user://nightbound_save.json` saved by the gameplay scene.
- New Game deletes that single save file first; this is intentional **and currently has no overwrite confirmation**.
- Load displays whether a save exists and directs the player to Continue; it is not a separate slot selector.
- Options saves reduced-motion and master-volume preferences in `user://nightbound_menu.cfg`.
- Controls use built-in Godot UI focus and navigation; mouse, keyboard, and gamepad focus are intended.

## Gameplay compatibility
The existing gameplay scene is unchanged: `res://scenes/main.tscn` builds Moonlit Valley and Veilwood and emits `NIGHTBOUND_SCENE_READY`. The title menu calls `get_tree().change_scene_to_file` to launch it.

## Scope and verification
The project includes several earlier asset backups; **their presence is not evidence that their models or video assets are imported into the active gameplay scene**. The title screen uses 2D concept art animation, not the 3D hero model. Animated GIF/MP4 demo assets remain separate.

GitHub CI should validate both title and gameplay startup. Interactive saving, keyboard navigation, and rendering still require manual Godot verification, beyond any automated parse/run checks.

## Test checklist
1. Start the project; observe intro and skip it with Enter or mouse.
2. Navigate menu using arrow keys, mouse and gamepad.
3. Open Options, move volume slider, toggle reduced motion, restart and verify persistence.
4. Start a new game and confirm playable world appears.
5. Save using P, return to menu by restarting, then confirm Continue is enabled.
6. Confirm all gameplay controls and both realms still work as before.
