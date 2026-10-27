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
var burst_pressed := false
var dash_pressed := false
var dash_unlocked := false

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
	add_solid_box(Vector3(0, -0.5, 0), Vector3(44, 1, 44), Color("#416b43"))
	for p in [Vector3(-12, 0.4, -9), Vector3(11, 1.2, -14), Vector3(17, 0.4, 9), Vector3(-17, 3.2, 13)]:
		add_solid_box(p, Vector3(8, 1.2, 8), Color("#668b58"))
	add_solid_box(Vector3(0, -0.1, 15), Vector3(14, 0.15, 8), Color("#3e9bc2"))
	add_solid_box(Vector3(0, 0.1, 7), Vector3(2.5, 0.4, 9), Color("#9b7047"))
	for p in [Vector3(-24, 0.5, -19), Vector3(24, 0.5, -18), Vector3(27, 0.5, 18), Vector3(-26, 0.5, 22)]:
		add_box(self, p, Vector3(2, 1.2, 1.7), Color("#777d7b"))
		add_box(self, p + Vector3(0, 2, 0), Vector3(0.45, 3, 0.45), Color("#76502e"))
		add_sphere(self, p + Vector3(0, 4, 0), 1.8, Color("#286b48"))
	# Realm portal
	add_box(self, Vector3(-2, 2.5, -18), Vector3(0.35, 5, 0.5), Color("#e4b85e"))
	add_box(self, Vector3(2, 2.5, -18), Vector3(0.35, 5, 0.5), Color("#e4b85e"))
	add_box(self, Vector3(0, 5, -18), Vector3(4.3, 0.35, 0.5), Color("#e4b85e"))
	add_sphere(self, Vector3(0, 2.6, -18), 1.35, Color("#9367e8"))
	for i in range(11):
		var p := Vector3(float((i * 7) % 31) - 15, 1.0 + float(i % 3) * 0.5, float((i * 11) % 31) - 15)
		make_crystal(p, "crystal_%02d" % i)
	for p in [Vector3(-8, 1.2, 0), Vector3(5, 1, -7), Vector3(20, 1, 3)]:
		var relic := add_sphere(self, p, 0.5, Color("#a9efff"))
		relic.visible = false
		secrets.append(relic)

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
	if Input.is_key_pressed(KEY_F) and not burst_pressed:
		player.velocity += -player.global_basis.z * 13.0
		burst_pressed = true
	elif not Input.is_key_pressed(KEY_F):
		burst_pressed = false
	if crystals >= 8:
		dash_unlocked = true
	if Input.is_key_pressed(KEY_SHIFT) and not dash_pressed and dash_unlocked:
		player.velocity += -player.global_basis.z * 18.0
		dash_pressed = true
		show_message("Shadow Dash!")
	elif not Input.is_key_pressed(KEY_SHIFT):
		dash_pressed = false
	player.move_and_slide()
	pulse_time = maxf(0.0, pulse_time - delta)
	if Input.is_action_just_pressed("echosense"):
		revealed = true
		pulse_time = 5.0
		for secret in secrets:
			secret.visible = true
		show_message("Echo pulse! Ancient relics revealed for a moment.")
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
	if revealed and pulse_time <= 0.0:
		revealed = false
		for secret in secrets:
			secret.visible = false
	refresh_hud()

func refresh_hud() -> void:
	if hud:
		hud.text = "NIGHTBOUND   •   Crystals: %d\nWASD Move  |  SPACE Leap  |  E Echosense  |  P Save  |  O Load" % crystals

func show_message(text_value: String) -> void:
	if message:
		message.text = text_value

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game") or (event is InputEventKey and event.pressed and event.keycode == KEY_P):
		save_game()
	elif event.is_action_pressed("load_game") or (event is InputEventKey and event.pressed and event.keycode == KEY_O):
		load_game()

func save_game() -> void:
	var data := {"crystals": crystals, "collected": collected, "player_position": [player.position.x, player.position.y, player.position.z] if player else [0, 1.5, 3]}
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
