extends Control
## Native Godot 4 title screen for Nightbound.
## The illustrated background is concept art; camera drift and motes are runtime animations.

const GAME_SCENE := "res://scenes/main.tscn"
const SAVE_PATH := "user://nightbound_save.json"
const CONFIG_PATH := "user://nightbound_menu.cfg"
const BACKDROP: Texture2D = preload("res://backups/2026-10-31/images/nightbound_title_background.png")

var _background: TextureRect
var _night_tint: ColorRect
var _intro_layer: ColorRect
var _menu_panel: PanelContainer
var _info_panel: PanelContainer
var _info_heading: Label
var _info_body: Label
var _settings_box: VBoxContainer
var _confirm_new_button: Button
var _info_close_button: Button
var _menu_buttons: Array[Button] = []
var _motes: Array[ColorRect] = []
var _mote_positions: Array[Vector2] = []
var _elapsed := 0.0
var _intro_finished := false
var _reduce_motion := false
var _master_volume := 0.8

func _ready() -> void:
    _load_preferences()
    _build_background()
    _build_menu()
    _build_info_panel()
    _build_intro()
    get_viewport().size_changed.connect(_refresh_layout)
    _refresh_layout()
    get_tree().create_timer(2.6).timeout.connect(_end_intro)
    print("NIGHTBOUND_MENU_READY")

func _build_background() -> void:
    _background = TextureRect.new()
    _background.name = "AnimatedConceptBackground"
    _background.texture = BACKDROP
    _background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_background)

    _night_tint = ColorRect.new()
    _night_tint.name = "MoonlightPulse"
    _night_tint.color = Color(0.018, 0.012, 0.065, 0.23)
    _night_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _night_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_night_tint)

    for index in range(22):
        var mote := ColorRect.new()
        mote.name = "MoonMote_%02d" % index
        mote.color = Color(0.58, 0.84, 1.0, 0.46) if index % 3 == 0 else Color(0.81, 0.55, 1.0, 0.45)
        mote.size = Vector2(3.0, 3.0) if index % 4 == 0 else Vector2(2.0, 2.0)
        mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(mote)
        _motes.append(mote)
        _mote_positions.append(Vector2(float((index * 37 + 17) % 97) / 97.0, float((index * 23 + 29) % 89) / 89.0))

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.025, 0.095, 0.83)
    style.border_color = Color(0.47, 0.46, 1.0, 0.88)
    style.set_border_width_all(2)
    style.set_corner_radius_all(14)
    style.content_margin_left = 18.0
    style.content_margin_right = 18.0
    style.content_margin_top = 14.0
    style.content_margin_bottom = 14.0
    return style

func _button_style(hovered: bool) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.27, 0.10, 0.60, 0.94) if hovered else Color(0.025, 0.065, 0.20, 0.88)
    style.border_color = Color(0.77, 0.48, 1.0) if hovered else Color(0.30, 0.54, 1.0)
    style.set_border_width_all(2)
    style.set_corner_radius_all(9)
    style.content_margin_left = 12.0
    style.content_margin_right = 12.0
    style.content_margin_top = 7.0
    style.content_margin_bottom = 7.0
    return style

func _make_button(caption: String, action: Callable) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(310.0, 44.0)
    button.focus_mode = Control.FOCUS_ALL
    button.add_theme_font_size_override("font_size", 23)
    button.add_theme_color_override("font_color", Color("#e9e3ff"))
    button.add_theme_color_override("font_hover_color", Color("#ffffff"))
    button.add_theme_stylebox_override("normal", _button_style(false))
    button.add_theme_stylebox_override("hover", _button_style(true))
    button.add_theme_stylebox_override("pressed", _button_style(true))
    button.add_theme_stylebox_override("focus", _button_style(true))
    button.pressed.connect(action)
    return button

func _build_menu() -> void:
    _menu_panel = PanelContainer.new()
    _menu_panel.name = "MainMenu"
    _menu_panel.add_theme_stylebox_override("panel", _panel_style())
    add_child(_menu_panel)
    var vertical := VBoxContainer.new()
    vertical.add_theme_constant_override("separation", 8)
    _menu_panel.add_child(vertical)

    var heading := Label.new()
    heading.text = "LA TUA AVVENTURA"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 20)
    heading.add_theme_color_override("font_color", Color("#cdb8ff"))
    vertical.add_child(heading)

    var actions: Array[Callable] = [
        _start_new_game, _continue_game, _load_game, _show_options, _show_extras, _quit_game
    ]
    var captions: Array[String] = [
        "▶  Nuova partita", "↻  Continua", "▣  Carica",
        "⚙  Opzioni", "★  Extra", "✕  Esci"
    ]
    for i in range(captions.size()):
        var button := _make_button(captions[i], actions[i])
        vertical.add_child(button)
        _menu_buttons.append(button)
    _menu_buttons[1].disabled = not FileAccess.file_exists(SAVE_PATH)

    var hint := Label.new()
    hint.text = "Invio / A: conferma     Esc / B: indietro"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 13)
    hint.add_theme_color_override("font_color", Color("#a9c9f5"))
    vertical.add_child(hint)

func _build_info_panel() -> void:
    _info_panel = PanelContainer.new()
    _info_panel.name = "InformationAndOptions"
    _info_panel.add_theme_stylebox_override("panel", _panel_style())
    _info_panel.custom_minimum_size = Vector2(460.0, 270.0)
    _info_panel.visible = false
    add_child(_info_panel)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 12)
    _info_panel.add_child(content)
    _info_heading = Label.new()
    _info_heading.add_theme_font_size_override("font_size", 28)
    _info_heading.add_theme_color_override("font_color", Color("#e2bdff"))
    content.add_child(_info_heading)
    _info_body = Label.new()
    _info_body.custom_minimum_size = Vector2(405.0, 60.0)
    _info_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _info_body.add_theme_font_size_override("font_size", 17)
    content.add_child(_info_body)

    _settings_box = VBoxContainer.new()
    _settings_box.add_theme_constant_override("separation", 6)
    content.add_child(_settings_box)
    var reduced_motion := CheckButton.new()
    reduced_motion.text = "Riduci animazioni del menù"
    reduced_motion.button_pressed = _reduce_motion
    reduced_motion.toggled.connect(_set_reduced_motion)
    _settings_box.add_child(reduced_motion)
    var volume_label := Label.new()
    volume_label.text = "Volume generale"
    _settings_box.add_child(volume_label)
    var volume_slider := HSlider.new()
    volume_slider.min_value = 0.0
    volume_slider.max_value = 1.0
    volume_slider.step = 0.05
    volume_slider.value = _master_volume
    volume_slider.custom_minimum_size = Vector2(405.0, 22.0)
    volume_slider.value_changed.connect(_set_volume)
    _settings_box.add_child(volume_slider)

    _confirm_new_button = _make_button("Sì, sovrascrivi e ricomincia", _confirm_new_game)
    _confirm_new_button.hide()
    content.add_child(_confirm_new_button)
    _info_close_button = _make_button("←  Indietro", _close_info)
    content.add_child(_info_close_button)

func _build_intro() -> void:
    _intro_layer = ColorRect.new()
    _intro_layer.name = "AnimatedIntroductionOverlay"
    _intro_layer.color = Color(0.006, 0.012, 0.05, 0.84)
    _intro_layer.mouse_filter = Control.MOUSE_FILTER_STOP
    _intro_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_intro_layer)
    var intro_words := Label.new()
    intro_words.text = "NIGHTBOUND\nIl richiamo della luna\n\nPremi un tasto per continuare"
    intro_words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    intro_words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    intro_words.add_theme_font_size_override("font_size", 38)
    intro_words.add_theme_color_override("font_color", Color("#e6d8ff"))
    intro_words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _intro_layer.add_child(intro_words)

func _refresh_layout() -> void:
    var viewport_size := get_viewport_rect().size
    if is_instance_valid(_background):
        _background.position = Vector2(-36.0, -24.0)
        _background.size = viewport_size + Vector2(72.0, 48.0)
        _background.pivot_offset = _background.size * 0.5
    if is_instance_valid(_menu_panel):
        _menu_panel.position = Vector2(24.0, clampf(viewport_size.y * 0.28, 110.0, 260.0))
    if is_instance_valid(_info_panel):
        _info_panel.position = (viewport_size - _info_panel.size) * 0.5

func _process(delta: float) -> void:
    _elapsed += delta
    if _reduce_motion:
        return
    _background.scale = Vector2.ONE * (1.03 + 0.008 * sin(_elapsed * 0.20))
    _background.rotation = 0.0018 * sin(_elapsed * 0.15)
    _night_tint.color.a = 0.22 + 0.025 * sin(_elapsed * 0.47)
    var viewport_size := get_viewport_rect().size
    for i in range(_motes.size()):
        var origin := _mote_positions[i]
        var drift := sin(_elapsed * (0.35 + float(i % 4) * 0.11) + float(i)) * 12.0
        _motes[i].position = Vector2(origin.x * viewport_size.x + drift, origin.y * viewport_size.y - fmod(_elapsed * (5.0 + float(i % 3)) + float(i) * 9.0, viewport_size.y))

func _unhandled_input(event: InputEvent) -> void:
    if not _intro_finished:
        if event is InputEventKey and event.pressed and not event.echo:
            _end_intro()
            get_viewport().set_input_as_handled()
        elif event is InputEventMouseButton and event.pressed:
            _end_intro()
            get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("ui_cancel") and _info_panel.visible:
        _close_info()
        get_viewport().set_input_as_handled()

func _end_intro() -> void:
    if _intro_finished:
        return
    _intro_finished = true
    var fade := create_tween()
    fade.tween_property(_intro_layer, "modulate:a", 0.0, 0.55)
    fade.tween_callback(_reveal_menu)

func _reveal_menu() -> void:
    _intro_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _intro_layer.hide()
    _menu_buttons[0].grab_focus()

func _show_info(heading: String, details: String, show_settings: bool = false) -> void:
    _info_heading.text = heading
    _info_body.text = details
    _settings_box.visible = show_settings
    _confirm_new_button.hide()
    _info_panel.visible = true
    _refresh_layout()
    _info_close_button.grab_focus()

func _close_info() -> void:
    _info_panel.hide()
    _menu_buttons[0].grab_focus()

func _show_options() -> void:
    _show_info("Opzioni", "Preferenze salvate localmente sul dispositivo.", true)

func _show_extras() -> void:
    _show_info("Extra", "Nightbound — avventura originale con un pipistrello protagonista.\n\nConcept e prototipo in sviluppo. Le immagini non sono screenshot di gameplay.")

func _load_game() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        _launch_game()
    else:
        _show_info("Nessun salvataggio", "Inizia una nuova partita. I progressi saranno salvati sul dispositivo.")

func _continue_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        _load_game()
        return
    _launch_game()

func _start_new_game() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        _show_info("Nuova partita", "Esiste già un salvataggio. Vuoi cancellarlo e ricominciare dall'inizio?")
        _confirm_new_button.show()
        _confirm_new_button.grab_focus()
        return
    _launch_game()

func _confirm_new_game() -> void:
    var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
    if error != OK:
        _show_info("Salvataggio protetto", "Non è stato possibile cancellare il salvataggio precedente.")
        return
    _launch_game()

func _launch_game() -> void:
    var error := get_tree().change_scene_to_file(GAME_SCENE)
    if error != OK:
        _show_info("Errore di avvio", "Impossibile aprire la scena di gioco. Codice: %d" % error)

func _quit_game() -> void:
    get_tree().quit()

func _set_reduced_motion(enabled: bool) -> void:
    _reduce_motion = enabled
    if enabled:
        _background.scale = Vector2.ONE
        _background.rotation = 0.0
    _save_preferences()

func _set_volume(volume: float) -> void:
    _master_volume = volume
    var bus := AudioServer.get_bus_index("Master")
    if bus >= 0:
        AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(0.01, volume)))
    _save_preferences()

func _load_preferences() -> void:
    var file := ConfigFile.new()
    if file.load(CONFIG_PATH) == OK:
        _reduce_motion = bool(file.get_value("visual", "reduce_motion", false))
        _master_volume = float(file.get_value("audio", "master_volume", 0.8))
    var bus := AudioServer.get_bus_index("Master")
    if bus >= 0:
        AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(0.01, _master_volume)))

func _save_preferences() -> void:
    var file := ConfigFile.new()
    file.set_value("visual", "reduce_motion", _reduce_motion)
    file.set_value("audio", "master_volume", _master_volume)
    file.save(CONFIG_PATH)
