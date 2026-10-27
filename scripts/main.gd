extends Node3D

const SAVE_PATH := "user://nightbound_save.json"
const GLIDE_MAX_STAMINA := 2.8
var glide_stamina := 0.0
var glide_active := false
var checkpoint_position := Vector3(0, 1.5, 3)
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
	environment.fog_enabled = true
	environment.fog_light_color = Color("#6577a6")
	environment.fog_density = 0.008
	environment.fog_sky_affect = 0.35
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
	# Layered cliff silhouettes add depth and break up the blocky horizon.
	for i in range(18):
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := -42.0 + float(i) * 5.0
		var x := side * (43.0 + float(i % 3) * 2.5)
		var rock := add_sphere(self, Vector3(x, 2.0 + float(i % 4) * 0.7, z), 3.0 + float(i % 3) * 0.8, Color("#343d59") if i % 2 == 0 else Color("#414967"))
		rock.scale = Vector3(1.25, 1.8 + float(i % 3) * 0.25, 1.0)
	# Small crystal clusters around the valley edges create more layered fantasy landmarks.
	for p in [Vector3(-18, 1.0, -30), Vector3(18, 1.0, -33), Vector3(-42, 3.0, 14), Vector3(42, 3.0, 15), Vector3(-12, 1.0, 38), Vector3(13, 1.0, 39)]:
		for k in range(3):
			var shard := add_sphere(self, p + Vector3((float(k) - 1.0) * 0.65, 0.55 + float(k % 2) * 0.25, 0), 0.32, Color("#6eeaf4") if k != 1 else Color("#a88aff"))
			shard.scale = Vector3(0.55, 1.9 + float(k % 2) * 0.6, 0.55)
	# Low shrubs and layered canopy clusters soften the block-built landscape.
	for p in [Vector3(-8, 0.1, -17), Vector3(8, 0.1, -20), Vector3(-18, 0.2, 8), Vector3(18, 0.2, 7), Vector3(-35, 1.2, -12), Vector3(35, 1.2, -12), Vector3(-35, 1.3, 18), Vector3(35, 1.3, 18), Vector3(-15, 0.2, 32), Vector3(15, 0.2, 32)]:
		for part in range(3):
			var bush := add_sphere(self, p + Vector3((float(part) - 1.0) * 0.7, 0.35 + float(part % 2) * 0.2, 0), 0.85, Color("#315b46") if part != 1 else Color("#467452"))
			bush.scale = Vector3(1.25, 0.8, 1.0)
	# Warm lanterns trace the bridge and the four outer exploration routes.
	for p in [Vector3(-4, 0, 5), Vector3(4, 0, 5), Vector3(-12, 0, -8), Vector3(-27, 1.0, -22), Vector3(12, 0, -12), Vector3(27, 1.0, -24), Vector3(-27, 1.0, 25), Vector3(27, 1.0, 26)]:
		add_lantern(p)
	# More natural tree silhouettes: tapered trunks, layered crowns, and moonlit leaf tips.
	for p in [Vector3(-22, 0.0, -5), Vector3(22, 0.0, -6), Vector3(-40, 1.0, 4), Vector3(40, 1.0, 5), Vector3(-20, 0.0, 30), Vector3(20, 0.0, 31), Vector3(-8, 0.0, 39), Vector3(8, 0.0, 40)]:
		var trunk := add_box(self, p + Vector3(0, 1.5, 0), Vector3(0.65, 3.0, 0.65), Color("#4d3b43"))
		trunk.rotation.z = randf_range(-0.08, 0.08)
		for crown in range(4):
			var offset := Vector3(randf_range(-0.75, 0.75), 2.7 + float(crown) * 0.55, randf_range(-0.45, 0.45))
			var foliage := add_sphere(self, p + offset, 1.15 - float(crown) * 0.12, Color("#244b48") if crown % 2 == 0 else Color("#315d53"))
			foliage.scale = Vector3(1.0, 1.25, 0.9)
	# Bridge rails and posts make the crossing read as a crafted wooden structure.
	for side in [-1.0, 1.0]:
		add_box(self, Vector3(side * 1.25, 0.65, 7), Vector3(0.14, 0.9, 9), Color("#68482f"))
		for z in [3.5, 5.5, 7.5, 9.5, 11.0]:
			add_box(self, Vector3(side * 1.25, 1.05, z), Vector3(0.22, 1.7, 0.22), Color("#815c3b"))
	# Rebuild the realm gate as a carved stone-and-crystal landmark, not a plain box frame.
	add_solid_box(Vector3(-2.25, 2.4, -18), Vector3(0.75, 4.8, 1.0), Color("#45445f"))
	add_solid_box(Vector3(2.25, 2.4, -18), Vector3(0.75, 4.8, 1.0), Color("#45445f"))
	add_solid_box(Vector3(0, 4.85, -18), Vector3(5.1, 0.75, 1.0), Color("#56516e"))
	for side in [-1.0, 1.0]:
		for y in [1.0, 2.1, 3.2, 4.2]:
			var rune := add_box(self, Vector3(side * 2.25, y, -17.42), Vector3(0.12, 0.42, 0.08), Color("#9b8cff"))
		var cap := add_sphere(self, Vector3(side * 2.25, 5.2, -18), 0.45, Color("#7a6f9b"))
		cap.scale = Vector3(1.0, 0.65, 0.85)
	# Portal center uses a flattened glowing crystal-like orb with layered rings.
	var portal_core := add_sphere(self, Vector3(0, 2.7, -18.05), 1.35, Color("#8759db"))
	portal_core.scale = Vector3(0.88, 1.2, 0.35)
	var core_glow := OmniLight3D.new()
	core_glow.position = Vector3(0, 2.8, -16.8)
	core_glow.light_color = Color("#9c75ff")
	core_glow.light_energy = 1.6
	core_glow.omni_range = 7.0
	add_child(core_glow)
	# Concentric luminous rings give the realm gate a stronger focal silhouette.
	for ring_scale in [1.0, 0.78]:
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.07 if ring_scale == 1.0 else 0.045
		ring_mesh.outer_radius = 1.65 * ring_scale
		ring.mesh = ring_mesh
		ring.position = Vector3(0, 2.6, -17.65)
		ring.rotation_degrees.x = 90
		ring.material_override = material(Color("#bba0ff") if ring_scale == 1.0 else Color("#68e9ff"), 0.25)
		add_child(ring)
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
		var ear := add_sphere(player, Vector3(side * 0.24, 1.0, -0.31), 0.16, Color("#292c45"))
		ear.scale = Vector3(0.65, 1.55, 0.55)
		var eye := add_sphere(player, Vector3(side * 0.16, 0.66, -0.77), 0.065, Color("#f8df8b"))
		eye.scale = Vector3(0.8, 1.0, 0.45)
		var wing := add_box(player, Vector3(side * 0.88, 0.22, 0.03), Vector3(1.15, 0.10, 0.58), Color("#59416f"))
		wing.rotation.z = side * -0.18
		var tip := add_sphere(player, Vector3(side * 1.38, 0.12, -0.08), 0.22, Color("#302641"))
		tip.scale = Vector3(1.8, 0.3, 0.75)
		for finger in range(3):
			var spar := add_box(player, Vector3(side * (0.78 + finger * 0.22), 0.18, 0.20 + finger * 0.08), Vector3(0.58, 0.045, 0.045), Color("#8a6da2"))
			spar.rotation.y = side * (0.18 + finger * 0.12)
	add_sphere(player, Vector3(0, 0.45, -0.79), 0.16, Color("#c6b5d9"))
	# Chest tuft and feet give the silhouette a more character-like, finished read.
	for tuft in range(3):
		var fur := add_sphere(player, Vector3((float(tuft) - 1.0) * 0.13, 0.05 - float(tuft % 2) * 0.08, -0.48), 0.12, Color("#82739f"))
		fur.scale = Vector3(0.7, 1.25, 0.65)
	for side in [-1.0, 1.0]:
		var foot := add_sphere(player, Vector3(side * 0.22, -0.43, -0.12), 0.14, Color("#b77a86"))
		foot.scale = Vector3(1.0, 0.55, 1.35)
		# Three tiny toe tips add a readable bat-like foot shape.
		for toe in range(3):
			var claw := add_sphere(player, Vector3(side * 0.22 + (float(toe) - 1.0) * 0.09, -0.47, -0.25), 0.045, Color("#e0c6d0"))
			claw.scale = Vector3(0.75, 0.65, 1.2)
	# Soft rim lighting separates the dark character from the night scene.
	var rim := OmniLight3D.new()
	rim.position = Vector3(0, 0.7, 0.3)
	rim.light_color = Color("#8f83ff")
	rim.light_energy = 0.65
	rim.omni_range = 4.0
	player.add_child(rim)

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
	hud.add_theme_font_size_override("font_size", 20)
	hud.add_theme_color_override("font_color", Color("#f4f0ff"))
	layer.add_child(hud)
	message = Label.new()
	message.position = Vector2(22, 100)
	message.size = Vector2(1000, 48)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 16)
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
		glide_active = Input.is_action_pressed("jump") and player.velocity.y < 0.5 and glide_stamina < GLIDE_MAX_STAMINA
		if glide_active:
			glide_stamina += delta
			player.velocity.y = maxf(player.velocity.y - 5.0 * delta, -3.0)
			player.velocity.x *= 1.015
			player.velocity.z *= 1.015
		else:
			player.velocity.y -= 24.0 * delta
	else:
		glide_active = false
		glide_stamina = 0.0
		if Input.is_action_just_pressed("jump"):
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
			if not collected_relics.has(relic.name):
				collected_relics.append(relic.name)
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
	var data := {"crystals": crystals, "collected": collected, "collected_relics": collected_relics, "checkpoint_position": [checkpoint_position.x, checkpoint_position.y, checkpoint_position.z], "player_position": [player.position.x, player.position.y, player.position.z] if player else [0, 1.5, 3]}
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
	var cp = parsed.get("checkpoint_position", [0, 1.5, 3])
	if cp is Array and cp.size() == 3:
		checkpoint_position = Vector3(float(cp[0]), float(cp[1]), float(cp[2]))
	relics_found = collected_relics.size()
	for i in range(secrets.size() - 1, -1, -1):
		if collected_relics.has(secrets[i].name):
			secrets[i].queue_free()
			secrets.remove_at(i)
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
