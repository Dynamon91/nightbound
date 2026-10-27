extends Node3D

const SAVE_PATH := "user://nightbound_save.json"
var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var message: Label
var crystals := 0
var revealed := false
var pulse_time := 0.0
var jump_speed := 10.5
var move_speed := 8.0
var collected: Array[String] = []
var crystal_objects: Dictionary = {}
var secrets: Array[MeshInstance3D] = []
var relics_found := 0
var collected_relics: Array[String] = []
var burst_pressed := false
var dash_pressed := false
var dash_unlocked := false
var portal_open := false
var victory_shown := false

func material(color: Color, roughness := 0.75) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = pos
	item.material_override = material(color)
	parent.add_child(item)
	return item

func add_lantern(pos: Vector3) -> void:
	# Warm route lights make landmarks readable against the cool moonlight.
	add_solid_box(pos + Vector3(0, 1.1, 0), Vector3(0.18, 2.2, 0.18), Color("#65452e"))
	add_box(self, pos + Vector3(0, 2.15, 0), Vector3(0.65, 0.12, 0.65), Color("#b88445"))
	add_sphere(self, pos + Vector3(0, 2.45, 0), 0.22, Color("#ffd58a"))
	var glow := OmniLight3D.new()
	glow.position = pos + Vector3(0, 2.5, 0)
	glow.light_color = Color("#ffb85c")
	glow.light_energy = 1.25
	glow.omni_range = 7.0
	add_child(glow)

func add_solid_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	add_box(body, Vector3.ZERO, size, color)

func add_sphere(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	item.mesh = mesh
	item.position = pos
	item.material_override = material(color, 0.35)
	parent.add_child(item)
	return item

func _ready() -> void:
	build_world()
	build_player()
	build_camera()
	build_hud()
	load_game()
	show_message("Explore the valley. Press E to reveal hidden echoes.")

func build_world() -> void:
	# Moonlit 3D presentation: cool ambient light and a warm key light.
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#10182d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#8195cf")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = environment
	add_child(world_env)
	var moonlight := DirectionalLight3D.new()
	moonlight.name = "Moonlight"
	moonlight.rotation_degrees = Vector3(-48, -32, 0)
	moonlight.light_color = Color("#b8ccff")
	moonlight.light_energy = 1.15
	moonlight.shadow_enabled = true
	add_child(moonlight)
	var fill_light := OmniLight3D.new()
	fill_light.name = "PortalGlow"
	fill_light.position = Vector3(0, 3, -15)
	fill_light.light_color = Color("#9c75ff")
	fill_light.light_energy = 2.0
	fill_light.omni_range = 12.0
	add_child(fill_light)
	# Broad valley floor: the prototype is deliberately scaled for roaming, not a tiny arena.
	add_solid_box(Vector3(0, -0.5, 0), Vector3(100, 1, 100), Color("#416b43"))
	# Raised exploration shelves around the valley, with multiple routes and glide-friendly gaps.
	for p in [Vector3(-12, 0.4, -9), Vector3(11, 1.2, -14), Vector3(17, 0.4, 9), Vector3(-17, 3.2, 13), Vector3(-30, 1.0, -20), Vector3(-38, 2.4, -28), Vector3(-27, 3.8, -36), Vector3(28, 1.0, -22), Vector3(38, 2.5, -32), Vector3(31, 4.0, -40), Vector3(-31, 1.0, 24), Vector3(-39, 2.6, 34), Vector3(-27, 4.0, 40), Vector3(29, 1.0, 25), Vector3(39, 2.8, 35), Vector3(27, 4.2, 42)]:
		add_solid_box(p, Vector3(8, 1.2, 8), Color("#668b58"))
	# Four natural stepping-stone routes lead out to the raised shelves.
	for p in [Vector3(-20, 0.1, -15), Vector3(-25, 0.5, -21), Vector3(-31, 1.5, -27), Vector3(20, 0.1, -16), Vector3(26, 0.5, -23), Vector3(32, 1.6, -29), Vector3(-20, 0.1, 17), Vector3(-26, 0.5, 24), Vector3(-32, 1.7, 30), Vector3(20, 0.1, 18), Vector3(26, 0.6, 25), Vector3(32, 1.8, 31)]:
		add_solid_box(p, Vector3(5, 0.6, 5), Color("#78965f"))
	# A shallow moonlit pool and a wooden crossing mark the central landmark.
	add_solid_box(Vector3(0, -0.1, 15), Vector3(14, 0.15, 8), Color("#3e9bc2"))
	add_solid_box(Vector3(0, 0.1, 7), Vector3(2.5, 0.4, 9), Color("#9b7047"))
	# Distinct distant rock formations help orient the player while exploring.
	for p in [Vector3(-44, 0.8, -5), Vector3(45, 0.8, 4), Vector3(-5, 0.8, 45), Vector3(5, 0.8, -45)]:
		add_box(self, p, Vector3(5, 2.5, 4), Color("#777d7b"))
		add_sphere(self, p + Vector3(0, 2.0, 0), 2.6, Color("#286b48"))
	for p in [Vector3(-24, 0.5, -19), Vector3(24, 0.5, -18), Vector3(27, 0.5, 18), Vector3(-26, 0.5, 22)]:
		add_box(self, p, Vector3(2, 1.2, 1.7), Color("#777d7b"))
		add_box(self, p + Vector3(0, 2, 0), Vector3(0.45, 3, 0.45), Color("#76502e"))
		add_sphere(self, p + Vector3(0, 4, 0), 1.8, Color("#286b48"))
	# Warm lanterns trace the bridge and the four outer exploration routes.
	for p in [Vector3(-4, 0, 5), Vector3(4, 0, 5), Vector3(-12, 0, -8), Vector3(-27, 1.0, -22), Vector3(12, 0, -12), Vector3(27, 1.0, -24), Vector3(-27, 1.0, 25), Vector3(27, 1.0, 26)]:
		add_lantern(p)
	# Realm portal
	add_box(self, Vector3(-2, 2.5, -18), Vector3(0.35, 5, 0.5), Color("#e4b85e"))
	add_box(self, Vector3(2, 2.5, -18), Vector3(0.35, 5, 0.5), Color("#e4b85e"))
	add_box(self, Vector3(0, 5, -18), Vector3(4.3, 0.35, 0.5), Color("#e4b85e"))
	add_sphere(self, Vector3(0, 2.6, -18), 1.35, Color("#9367e8"))
	# Collectibles are distributed across the expanded valley and its outer routes.
	var crystal_positions: Array[Vector3] = [
		Vector3(-5, 1.0, -5), Vector3(7, 1.5, -12), Vector3(-14, 1.2, -10),
		Vector3(-25, 1.5, -21), Vector3(-38, 3.2, -29), Vector3(25, 1.5, -23),
		Vector3(38, 3.4, -33), Vector3(-25, 1.5, 24), Vector3(-38, 3.5, 35),
		Vector3(25, 1.6, 25), Vector3(38, 3.7, 36)
	]
	for i in range(crystal_positions.size()):
		make_crystal(crystal_positions[i], "crystal_%02d" % i)
	var relic_positions: Array[Vector3] = [Vector3(-8, 1.2, 0), Vector3(5, 1, -7), Vector3(20, 1, 3), Vector3(-37, 4.7, -38), Vector3(37, 4.8, 40)]
	for i in range(relic_positions.size()):
		var relic := add_sphere(self, relic_positions[i], 0.5, Color("#a9efff"))
		relic.name = "relic_%d" % i
		relic.visible = false
		if not collected_relics.has(relic.name):
			secrets.append(relic)
		else:
			relics_found += 1
			if not collected_relics.has(relic.name):
				collected_relics.append(relic.name)
			relic.queue_free()

func make_crystal(pos: Vector3, id: String) -> void:
	var c := add_sphere(self, pos, 0.38, Color("#67f2ee"))
	c.name = id
	crystal_objects[id] = {"node": c, "base": pos, "phase": randf() * TAU}

func build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "BatPlayer"
	player.position = Vector3(0, 1.5, 3)
	add_child(player)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.48
	shape.height = 1.6
	collision.shape = shape
	player.add_child(collision)
	var body := add_sphere(player, Vector3(0, 0.15, 0), 0.58, Color("#292c45"))
	body.scale = Vector3(0.85, 1.15, 0.7)
	add_sphere(player, Vector3(0, 0.55, -0.22), 0.35, Color("#414866"))
	for side in [-1.0, 1.0]:
		var wing := add_box(player, Vector3(side * 0.82, 0.25, 0), Vector3(0.9, 0.08, 0.5), Color("#5c4a85"))
		wing.rotation.z = side * -0.2
		add_sphere(player, Vector3(side * 0.22, 0.62, -0.48), 0.075, Color("#f8df8b"))

func build_camera() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0, 7, 11)
	camera.rotation_degrees = Vector3(-24, 0, 0)
	camera.current = true
	player.add_child(camera)
	camera.position = Vector3(0, 6.5, 10.5)
	camera.look_at(Vector3(0, 0.7, 0))

func build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(22, 18)
	hud.add_theme_font_size_override("font_size", 22)
	hud.add_theme_color_override("font_color", Color("#f4f0ff"))
	layer.add_child(hud)
	message = Label.new()
	message.position = Vector2(22, 62)
	message.add_theme_font_size_override("font_size", 17)
	message.add_theme_color_override("font_color", Color("#b7f8f3"))
	layer.add_child(message)
	refresh_hud()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	# Safety net: return the bat to the valley if it falls out of the playable area.
	if player.global_position.y < -12.0:
		player.velocity = Vector3.ZERO
		player.position = Vector3(0, 1.5, 3)
		show_message("The night wind carries you back to the valley.")
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3(input.x, 0, input.y)
	player.velocity.x = dir.x * move_speed
	player.velocity.z = dir.z * move_speed
	if dir.length() > 0.05:
		player.rotation.y = atan2(-dir.x, -dir.z)
	if not player.is_on_floor():
		player.velocity.y -= 24.0 * delta
		if Input.is_action_pressed("jump"):
			player.velocity.y = maxf(player.velocity.y, -2.0)
	elif Input.is_action_just_pressed("jump"):
		player.velocity.y = jump_speed
	if Input.is_action_pressed("burst") and not burst_pressed:
		player.velocity += -player.global_basis.z * 13.0
		burst_pressed = true
	elif not Input.is_action_pressed("burst"):
		burst_pressed = false
	if crystals >= 8:
		dash_unlocked = true
	if Input.is_action_pressed("shadow_dash") and not dash_pressed and dash_unlocked:
		player.velocity += -player.global_basis.z * 18.0
		dash_pressed = true
		show_message("Shadow Dash!")
	elif not Input.is_action_pressed("shadow_dash"):
		dash_pressed = false
	player.move_and_slide()
	pulse_time = maxf(0.0, pulse_time - delta)
	if Input.is_action_just_pressed("echosense"):
		revealed = true
		pulse_time = 5.0
		for secret in secrets:
			secret.visible = true
		show_message("Echo pulse! Ancient relics revealed for a moment.")
	# Revealed relics can be collected by approaching them before the pulse fades.
	for i in range(secrets.size() - 1, -1, -1):
		var relic: MeshInstance3D = secrets[i]
		if is_instance_valid(relic) and relic.visible and relic.global_position.distance_to(player.global_position) < 1.25:
			relics_found += 1
			relic.queue_free()
			secrets.remove_at(i)
			show_message("Ancient relic found! Echoes discovered: %d/5" % relics_found)
			save_game()
	for id in crystal_objects.keys():
		var entry: Dictionary = crystal_objects[id]
		var node: MeshInstance3D = entry["node"]
		if is_instance_valid(node):
			node.position.y = float(entry["base"].y) + sin(Time.get_ticks_msec() / 350.0 + float(entry["phase"])) * 0.14
			node.rotate_y(delta * 1.4)
			if node.global_position.distance_to(player.global_position) < 1.25:
				crystals += 1
				collected.append(id)
				node.queue_free()
				crystal_objects.erase(id)
				show_message("Crystal collected! Keep exploring.")
				save_game()
	if crystals >= 11 and not portal_open:
		portal_open = true
		show_message("All 11 crystals gathered! The Realm Gate awakens.")
	if portal_open and not victory_shown and player.global_position.distance_to(Vector3(0, 2.5, -18)) < 3.0:
		victory_shown = true
		show_message("REALM GATE OPEN — You have awakened the ancient passage!")
	if revealed and pulse_time <= 0.0:
		revealed = false
		for secret in secrets:
			secret.visible = false
	refresh_hud()

func refresh_hud() -> void:
	if hud:
		hud.text = "NIGHTBOUND   •   Crystals: %d/11   •   Echoes: %d/5%s\nWASD Move  |  SPACE Leap/Glide  |  F Burst  |  E Echosense\nSHIFT Shadow Dash (8 crystals)  |  P Save  |  O Load" % [crystals, relics_found, "  •  GATE OPEN" if portal_open else ""]

func show_message(text_value: String) -> void:
	if message:
		message.text = text_value

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game") or (event is InputEventKey and event.pressed and event.keycode == KEY_P):
		save_game()
	elif event.is_action_pressed("load_game") or (event is InputEventKey and event.pressed and event.keycode == KEY_O):
		load_game()

func save_game() -> void:
	var data := {"crystals": crystals, "collected": collected, "collected_relics": collected_relics, "player_position": [player.position.x, player.position.y, player.position.z] if player else [0, 1.5, 3]}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		show_message("Progress saved.")
 
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	crystals = int(parsed.get("crystals", 0))
	collected = parsed.get("collected", [])
	collected_relics = parsed.get("collected_relics", [])
	relics_found = collected_relics.size()
	var p = parsed.get("player_position", [0, 1.5, 3])
	if player and p is Array and p.size() == 3:
		player.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	for id in collected:
		if crystal_objects.has(id):
			var entry: Dictionary = crystal_objects[id]
			if is_instance_valid(entry["node"]):
				entry["node"].queue_free()
			crystal_objects.erase(id)
	refresh_hud()
	show_message("Saved progress loaded.")
