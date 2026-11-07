# Hero Bat V6 — native Godot 4 review scene

This asset is previously archived as `backup/assets/models/Nightbound_Hero_Bat_V6_Animated.glb`.

The new scene `scenes/hero_showcase.tscn`, with `scripts/hero_showcase.gd`, instantiates the **actual glTF/GLB** inside Godot, under a real lighting rig and orbiting camera. From the title menu, open **Extra → Vedi Hero Bat V6 in 3D**.

- Press 1: Glide
- Press 2: Flap
- Press 3: Bank_Left
- Press 4: Bank_Right
- Press Esc/B or click the button to go back.

The four clips were reported in the GLB metadata. Availability and playback depend on Godot's importer naming; the review scene checks `AnimationPlayer.has_animation` before attempting playback.

**Status:** This is a model review scene, NOT a player-controller replacement and not proof of correct geometry/facial resemblance to the concept art. The Godot CI run validates that the GLB imports and the preview scene starts; visual review remains required.
