extends Node3D
## Godot model-review scene: inspect the real archived Hero Bat V6 GLB.
## The model is a work-in-progress and is not the active gameplay controller.

const HERO_MODEL_PATH := "res://backup/assets/models/Nightbound_Hero_Bat_V6_Animated.glb"
const CLIPS: Array[String] = ["Glide", "Flap", "Bank_Left", "Bank_Right"]

var _hero: Node3D
var _camera: Camera3D
var _player: AnimationPlayer
var _caption: Label
var _clock := 0.0
var _clip_index := 0

func _ready() -> void:
    _make_environment()
    _make_pedestal()
    _make_camera()
    _make_interface()
    var resource := load(HERO_MODEL_PATH)
    if not resource is PackedScene:
        push_error("Cannot import Nightbound Hero V6 GLB: " + HERO_MODEL_PATH)
        return
    _hero = (resource as PackedScene).instantiate() as Node3D
    if _hero == null:
        push_error("Hero V6 imported scene is not Node3D.")
        return
    _hero.name = "HeroBatV6Review"
    _hero.position = Vector3(0.0, 1.6, 0.0)
    _hero.scale = Vector3.ONE * 0.95
    add_child(_hero)
    _player = _find_animation_player(_hero)
    _play_clip(0)
    var clips_found := 0
    for clip in CLIPS:
        if not _resolve_clip(clip).is_empty():
            clips_found += 1
    if clips_found == CLIPS.size():
        print("NIGHTBOUND_HERO_ANIMATIONS_READY")
    else:
        push_warning("Only %d of %d expected GLB animations were imported." % [clips_found, CLIPS.size()])
    print("NIGHTBOUND_HERO_MODEL_LOADED")
    print("NIGHTBOUND_HERO_SHOWCASE_READY")

func _make_environment() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#090d2e")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#8d86e2")
    environment.ambient_light_energy = 0.7
    world.environment = environment
    add_child(world)

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-45.0, -38.0, 0.0)
    key.light_color = Color("#d2d7ff")
    key.light_energy = 1.35
    add_child(key)
    var violet_rim := OmniLight3D.new()
    violet_rim.position = Vector3(2.8, 3.6, -2.1)
    violet_rim.light_color = Color("#b959f2")
    violet_rim.light_energy = 2.3
    violet_rim.omni_range = 8.0
    add_child(violet_rim)

func _make_pedestal() -> void:
    var display := MeshInstance3D.new()
    display.name = "DisplayPedestal"
    var mesh := CylinderMesh.new()
    mesh.top_radius = 2.0
    mesh.bottom_radius = 2.3
    mesh.height = 0.30
    mesh.radial_segments = 32
    display.mesh = mesh
    display.position = Vector3(0.0, -0.25, 0.0)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#26335c")
    material.metallic = 0.24
    material.roughness = 0.37
    display.material_override = material
    add_child(display)

func _make_camera() -> void:
    _camera = Camera3D.new()
    _camera.name = "OrbitCamera"
    _camera.current = true
    _camera.fov = 58.0
    add_child(_camera)

func _make_interface() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 10
    add_child(layer)
    var overlay := Control.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(overlay)

    var bar := ColorRect.new()
    bar.color = Color(0.02, 0.03, 0.12, 0.78)
    bar.position = Vector2(20.0, 18.0)
    bar.size = Vector2(780.0, 115.0)
    overlay.add_child(bar)

    var heading := Label.new()
    heading.text = "NIGHTBOUND   •   HERO BAT V6"
    heading.position = Vector2(38.0, 24.0)
    heading.add_theme_font_size_override("font_size", 29)
    heading.add_theme_color_override("font_color", Color("#ead8ff"))
    overlay.add_child(heading)

    _caption = Label.new()
    _caption.position = Vector2(38.0, 66.0)
    _caption.custom_minimum_size = Vector2(740.0, 32.0)
    _caption.add_theme_font_size_override("font_size", 17)
    _caption.add_theme_color_override("font_color", Color("#c3e2ff"))
    overlay.add_child(_caption)

    var hint := Label.new()
    hint.text = "1–4: animazioni    •    Esc / B: torna al menù    •    modello in sviluppo"
    hint.position = Vector2(38.0, 98.0)
    hint.add_theme_font_size_override("font_size", 13)
    overlay.add_child(hint)

    var back_button := Button.new()
    back_button.text = "←  Torna al menù"
    back_button.position = Vector2(22.0, 648.0)
    back_button.custom_minimum_size = Vector2(240.0, 48.0)
    back_button.pressed.connect(_go_back)
    overlay.add_child(back_button)

func _find_animation_player(node: Node) -> AnimationPlayer:
    if node is AnimationPlayer:
        return node as AnimationPlayer
    for child in node.get_children():
        var candidate := _find_animation_player(child)
        if candidate != null:
            return candidate
    return null

func _resolve_clip(clip: String) -> String:
    if _player == null:
        return ""
    if _player.has_animation(clip):
        return clip
    for candidate in _player.get_animation_list():
        if String(candidate).ends_with(clip):
            return String(candidate)
    return ""

func _play_clip(index: int) -> void:
    _clip_index = clampi(index, 0, CLIPS.size() - 1)
    var clip := CLIPS[_clip_index]
    var imported_name := _resolve_clip(clip)
    if not imported_name.is_empty():
        _player.play(imported_name)
        _caption.text = "Animazione: " + clip + "   •   GLB importato in Godot"
    else:
        _caption.text = "Modello 3D importato • clip " + clip + " non disponibile"

func _process(delta: float) -> void:
    _clock += delta
    if _camera != null:
        _camera.position = Vector3(sin(_clock * 0.22) * 5.1, 2.45, cos(_clock * 0.22) * 5.1)
        _camera.look_at(Vector3(0, 1.55, 0))
    if _hero != null:
        _hero.position.y = 1.6 + sin(_clock * 1.7) * 0.06

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _go_back()
        get_viewport().set_input_as_handled()
        return
    if event is InputEventKey and event.pressed and not event.echo:
        match event.physical_keycode:
            KEY_1: _play_clip(0)
            KEY_2: _play_clip(1)
            KEY_3: _play_clip(2)
            KEY_4: _play_clip(3)

func _go_back() -> void:
    get_tree().change_scene_to_file("res://scenes/title_menu.tscn")
