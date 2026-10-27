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
var portal_core_node: MeshInstance3D
var portal_glow_light: OmniLight3D
var portal_anim_time := 0.0
var current_realm := "Moonlit Valley"
var realm_transitioned := false
var veilwood_seeds := 0
var collected_veilwood_seeds: Array[String] = []
var veilwood_seed_objects: Dictionary = {}
var heart_blooms: Array[MeshInstance3D] = []
var heart_tree_light: OmniLight3D
var veilwood_motes: Array[MeshInstance3D] = []

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

func add_rock(parent: Node3D, pos: Vector3, size: Vector3, color: Color, seed_value: int) -> MeshInstance3D:
	# Faceted, irregular silhouettes read as moonlit stone rather than smooth placeholder blobs.
	var item := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 7
	mesh.rings = 4
	item.mesh = mesh
	item.position = pos
	item.scale = size
	var rock_mat := material(color, 0.92)
	rock_mat.metallic = 0.04
	item.material_override = rock_mat
	item.rotation = Vector3(float(seed_value % 5) * 0.09, float(seed_value % 7) * 0.31, float(seed_value % 3) * 0.07)
	parent.add_child(item)
	return item

func add_wing_membrane(parent: Node3D, side: float) -> void:
	# A thin, scalloped triangular membrane gives the bat a readable wing silhouette.
	var mesh_instance := MeshInstance3D.new()
	var wing_mesh := ArrayMesh.new()
	var vertices := PackedVector3Array([
		Vector3(side * 0.28, 0.30, 0.02),
		Vector3(side * 1.48, 0.18, 0.02),
		Vector3(side * 1.18, -0.18, 0.02),
		Vector3(side * 0.92, -0.02, 0.02),
		Vector3(side * 0.66, -0.30, 0.02),
		Vector3(side * 0.42, -0.04, 0.02)
	])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 5])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	wing_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = wing_mesh
	var membrane := material(Color("#493258"), 0.8)
	membrane.cull_mode = BaseMaterial3D.CULL_DISABLED
	membrane.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	membrane.emission_enabled = true
	membrane.emission = Color("#302344")
	membrane.emission_energy_multiplier = 0.18
	mesh_instance.material_override = membrane
	parent.add_child(mesh_instance)

func add_crystal_shard(parent: Node3D, pos: Vector3, height: float, color: Color, width := 0.32) -> MeshInstance3D:
	# Low-sided tapered prism gives crystals a deliberate faceted silhouette.
	var item := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = width * 0.08
	mesh.bottom_radius = width
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	item.mesh = mesh
	item.position = pos
	var crystal_mat := material(color, 0.22)
	crystal_mat.metallic = 0.12
	crystal_mat.emission_enabled = true
	crystal_mat.emission = color
	crystal_mat.emission_energy_multiplier = 0.7
	item.material_override = crystal_mat
	parent.add_child(item)
	return item

func _ready() -> void:
	build_world()
	build_veilwood()
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
		add_rock(self, p, Vector3(2.5, 1.25, 2.0), Color("#697487"), int(abs(p.x + p.z)))
		var crown := add_sphere(self, p + Vector3(0, 2.0, 0), 2.6, Color("#286b48"))
		crown.scale = Vector3(1.0, 0.85, 1.0)
	for p in [Vector3(-24, 0.5, -19), Vector3(24, 0.5, -18), Vector3(27, 0.5, 18), Vector3(-26, 0.5, 22)]:
		add_rock(self, p, Vector3(1.5, 0.9, 1.25), Color("#6e7487"), int(abs(p.x + p.z)))
		add_box(self, p + Vector3(0, 2, 0), Vector3(0.45, 3, 0.45), Color("#76502e"))
		var crown := add_sphere(self, p + Vector3(0, 4, 0), 1.8, Color("#286b48"))
		crown.scale = Vector3(1.0, 1.25, 0.9)
	# Layered cliff silhouettes add depth and break up the blocky horizon.
	for i in range(18):
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := -42.0 + float(i) * 5.0
		var x := side * (43.0 + float(i % 3) * 2.5)
		var rock := add_rock(self, Vector3(x, 2.0 + float(i % 4) * 0.7, z), Vector3(3.8 + float(i % 3) * 0.55, 3.0 + float(i % 3) * 0.45, 3.0), Color("#343d59") if i % 2 == 0 else Color("#414967"), i)
		rock.rotation.z += 0.08 if i % 2 == 0 else -0.06
	# Small crystal clusters around the valley edges create more layered fantasy landmarks.
	for p in [Vector3(-18, 1.0, -30), Vector3(18, 1.0, -33), Vector3(-42, 3.0, 14), Vector3(42, 3.0, 15), Vector3(-12, 1.0, 38), Vector3(13, 1.0, 39)]:
		for k in range(3):
			var shard := add_crystal_shard(self, p + Vector3((float(k) - 1.0) * 0.65, 0.55 + float(k % 2) * 0.25, 0), 1.15 + float(k % 2) * 0.35, Color("#6eeaf4") if k != 1 else Color("#a88aff"), 0.28)
			shard.rotation.z = (float(k) - 1.0) * 0.12
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
			var rune_mat := material(Color("#bbaaff"), 0.3)
			rune_mat.emission_enabled = true
			rune_mat.emission = Color("#9b72ff")
			rune_mat.emission_energy_multiplier = 0.9
			rune.material_override = rune_mat
		var cap := add_sphere(self, Vector3(side * 2.25, 5.2, -18), 0.45, Color("#7a6f9b"))
		cap.scale = Vector3(1.0, 0.65, 0.85)
	# Portal center uses a flattened glowing crystal-like orb with layered rings.
	portal_core_node = add_sphere(self, Vector3(0, 2.7, -18.05), 1.35, Color("#342c58"))
	portal_core_node.scale = Vector3(0.88, 1.2, 0.18)
	portal_glow_light = OmniLight3D.new()
	portal_glow_light.name = "RealmGateCoreLight"
	portal_glow_light.position = Vector3(0, 2.8, -16.8)
	portal_glow_light.light_color = Color("#9c75ff")
	portal_glow_light.light_energy = 0.25
	portal_glow_light.omni_range = 7.0
	add_child(portal_glow_light)
	# Concentric luminous rings give the realm gate a stronger focal silhouette.
	for ring_scale in [1.0, 0.78]:
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.07 if ring_scale == 1.0 else 0.045
		ring_mesh.outer_radius = 1.65 * ring_scale
		ring.mesh = ring_mesh
		ring.position = Vector3(0, 2.6, -17.65)
		ring.rotation_degrees.x = 90
		var ring_mat := material(Color("#bba0ff") if ring_scale == 1.0 else Color("#68e9ff"), 0.25)
		ring_mat.emission_enabled = true
		ring_mat.emission = Color("#9c75ff") if ring_scale == 1.0 else Color("#68e9ff")
		ring_mat.emission_energy_multiplier = 0.75
		ring.material_override = ring_mat
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

func build_veilwood() -> void:
	# A separate destination beyond the first gate: a bioluminescent forest.
	add_solid_box(Vector3(130, -0.5, 0), Vector3(76, 1, 76), Color("#252d50"))
	for p in [Vector3(118, 0.2, -8), Vector3(126, 0.7, -14), Vector3(137, 1.3, -20), Vector3(146, 2.0, -26), Vector3(138, 0.6, 10), Vector3(149, 1.4, 18), Vector3(158, 2.0, 25)]:
		add_solid_box(p, Vector3(7, 0.8, 7), Color("#3c466f"))
	for i in range(13):
		var side := -1.0 if i % 2 == 0 else 1.0
		var p := Vector3(130.0 + side * (12.0 + float(i % 4) * 5.0), 0.0, -30.0 + float(i) * 5.0)
		var trunk := add_box(self, p + Vector3(0, 3.0, 0), Vector3(0.8, 6.0 + float(i % 3), 0.8), Color("#37304f"))
		trunk.rotation.z = side * 0.08
		for layer in range(3):
			var crown := add_sphere(self, p + Vector3(0, 5.0 + float(layer) * 1.15, 0), 2.0 - float(layer) * 0.25, Color("#4c3679") if layer % 2 == 0 else Color("#285b70"))
			crown.scale = Vector3(1.0, 0.8, 1.0)
		var mote := add_sphere(self, p + Vector3(side * 1.3, 2.0, 0.5), 0.18, Color("#7ff8ef"))
		mote.name = "VeilwoodWisp_%02d" % i
		var mote_mat := mote.material_override as StandardMaterial3D
		if mote_mat:
			mote_mat.emission_enabled = true
			mote_mat.emission = Color("#65e9ff")
			mote_mat.emission_energy_multiplier = 1.8
		veilwood_motes.append(mote)
		var glow := OmniLight3D.new()
		glow.position = mote.position
		glow.light_color = Color("#65e9ff")
		glow.light_energy = 1.4
		glow.omni_range = 5.0
		add_child(glow)
	add_solid_box(Vector3(130, 4.0, -31), Vector3(2.2, 8.0, 2.2), Color("#55406c"))
	for angle in range(8):
		var a := float(angle) * TAU / 8.0
		var bloom := add_crystal_shard(self, Vector3(130 + cos(a) * 4.0, 5.0 + sin(a * 2.0) * 1.2, -31 + sin(a) * 4.0), 2.4, Color("#d28aff") if angle % 2 == 0 else Color("#69f2ed"), 0.42)
		bloom.rotation.z = cos(a) * 0.22
		heart_blooms.append(bloom)
	heart_tree_light = OmniLight3D.new()
	heart_tree_light.position = Vector3(130, 5.0, -31)
	heart_tree_light.light_color = Color("#b16bff")
	heart_tree_light.light_energy = 1.0 if veilwood_seeds < 5 else 4.5
	heart_tree_light.omni_range = 17.0
	add_child(heart_tree_light)
	for p in [Vector3(112, 2.5, -18), Vector3(151, 3.0, -8), Vector3(116, 2.8, 20), Vector3(153, 3.5, 14), Vector3(130, 1.0, 30)]:
		add_crystal_shard(self, p, 1.7, Color("#7ceff5"), 0.3)
		add_crystal_shard(self, p + Vector3(0.65, 0.35, 0), 1.1, Color("#bd7cff"), 0.24)
	# Five persistent Moonseeds form the first optional objective in this realm.
	var seed_positions: Array[Vector3] = [Vector3(111, 1.1, -4), Vector3(143, 1.4, -13), Vector3(155, 2.1, 23), Vector3(115, 1.1, 23), Vector3(130, 1.4, -24)]
	for i in range(seed_positions.size()):
		var seed_id := "moonseed_%02d" % i
		var seed := add_crystal_shard(self, seed_positions[i], 0.85, Color("#f0a8ff"), 0.3)
		seed.name = seed_id
		seed.rotation.z = 0.12
		var seed_mat := seed.material_override as StandardMaterial3D
		if seed_mat:
			seed_mat.emission_energy_multiplier = 1.35
		veilwood_seed_objects[seed_id] = seed

func make_crystal(pos: Vector3, id: String) -> void:
	var c := add_crystal_shard(self, pos, 0.95, Color("#67f2ee"), 0.34)
	c.name = id
	var base_mat := c.material_override as StandardMaterial3D
	if base_mat:
		base_mat.emission_energy_multiplier = 1.15
	c.rotation.z = 0.08
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
		add_wing_membrane(player, side)
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
	# Slow, offset drift keeps the Veilwood alive without distracting from traversal.
	var ambience_time := float(Time.get_ticks_msec()) / 1000.0
	for i in range(veilwood_motes.size()):
		var mote: MeshInstance3D = veilwood_motes[i]
		if is_instance_valid(mote):
			var phase := float(i) * 1.73
			mote.position.y += sin(ambience_time * 1.1 + phase) * delta * 0.32
			mote.position.x += cos(ambience_time * 0.55 + phase) * delta * 0.12
	for i in range(heart_blooms.size()):
		var bloom: MeshInstance3D = heart_blooms[i]
		if is_instance_valid(bloom):
			bloom.rotate_y(delta * (0.12 if veilwood_seeds < 5 else 0.32))
			var bloom_mat := bloom.material_override as StandardMaterial3D
			if bloom_mat:
				bloom_mat.emission_energy_multiplier = (2.8 if veilwood_seeds >= 5 else 0.7) + sin(ambience_time * 1.8 + float(i)) * 0.18
	if is_instance_valid(heart_tree_light):
		heart_tree_light.light_energy = (4.5 if veilwood_seeds >= 5 else 1.0) + sin(ambience_time * 1.4) * (0.35 if veilwood_seeds >= 5 else 0.12)
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
	for seed_id in veilwood_seed_objects.keys():
		var seed_node: MeshInstance3D = veilwood_seed_objects[seed_id]
		if is_instance_valid(seed_node):
			seed_node.rotate_y(delta * 1.0)
			if seed_node.global_position.distance_to(player.global_position) < 1.25:
				veilwood_seeds += 1
				collected_veilwood_seeds.append(seed_id)
				seed_node.queue_free()
				veilwood_seed_objects.erase(seed_id)
				show_message("Moonseed gathered! Veilwood seeds: %d/5" % veilwood_seeds)
				if veilwood_seeds == 5:
					for bloom in heart_blooms:
						var bloom_mat := bloom.material_override as StandardMaterial3D
						if bloom_mat:
							bloom_mat.emission_enabled = true
							bloom_mat.emission_energy_multiplier = 2.8
					if is_instance_valid(heart_tree_light):
						heart_tree_light.light_energy = 4.5
					show_message("VEILWOOD RESTORED — all five Moonseeds awaken the Heart-Tree!")
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
		portal_anim_time = 0.0
		show_message("All 11 crystals gathered! The Realm Gate awakens.")
	if portal_open:
		portal_anim_time += delta
		if is_instance_valid(portal_core_node):
			var opening := minf(portal_anim_time / 1.8, 1.0)
			portal_core_node.scale = Vector3(0.88, 1.2, 0.18 + opening * 0.22)
			var core_material := portal_core_node.material_override as StandardMaterial3D
			if core_material:
				core_material.albedo_color = Color("#342c58").lerp(Color("#a86bff"), opening)
				core_material.emission_enabled = true
				core_material.emission = Color("#8e56ff")
				core_material.emission_energy_multiplier = opening * 1.8
		if is_instance_valid(portal_glow_light):
			portal_glow_light.light_energy = minf(portal_anim_time / 1.8, 1.0) * 2.4
		if not realm_transitioned and portal_anim_time >= 1.8 and player.global_position.distance_to(Vector3(0, 2.5, -18)) < 3.0:
			realm_transitioned = true
			current_realm = "The Veilwood"
			player.velocity = Vector3.ZERO
			player.global_position = Vector3(130, 2.0, 4)
			checkpoint_position = player.global_position
			show_message("REALM SHIFT — Welcome to the Veilwood, a new realm beyond the gate!")
			save_game()
	if revealed and pulse_time <= 0.0:
		revealed = false
		for secret in secrets:
			secret.visible = false
	refresh_hud()

func refresh_hud() -> void:
	if hud:
		hud.text = "NIGHTBOUND  •  %s\nCrystals: %d/11  •  Echoes: %d/5  •  Moonseeds: %d/5%s\nWASD Move  |  SPACE Leap/Glide  |  F Burst  |  E Echosense\nSHIFT Shadow Dash (8 crystals)  |  P Save  |  O Load" % [current_realm, crystals, relics_found, veilwood_seeds, "  •  GATE OPEN" if portal_open else ""]

func show_message(text_value: String) -> void:
	if message:
		message.text = text_value

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game") or (event is InputEventKey and event.pressed and event.keycode == KEY_P):
		save_game()
	elif event.is_action_pressed("load_game") or (event is InputEventKey and event.pressed and event.keycode == KEY_O):
		load_game()

func save_game() -> void:
	var data := {"crystals": crystals, "current_realm": current_realm, "veilwood_seeds": veilwood_seeds, "collected_veilwood_seeds": collected_veilwood_seeds, "collected": collected, "collected_relics": collected_relics, "checkpoint_position": [checkpoint_position.x, checkpoint_position.y, checkpoint_position.z], "player_position": [player.position.x, player.position.y, player.position.z] if player else [0, 1.5, 3]}
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
	current_realm = str(parsed.get("current_realm", "Moonlit Valley"))
	veilwood_seeds = int(parsed.get("veilwood_seeds", 0))
	collected_veilwood_seeds = parsed.get("collected_veilwood_seeds", [])
	realm_transitioned = current_realm == "The Veilwood"
	portal_open = crystals >= 11
	if portal_open:
		portal_anim_time = 1.8
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
	if veilwood_seeds >= 5:
		for bloom in heart_blooms:
			var bloom_mat := bloom.material_override as StandardMaterial3D
			if bloom_mat:
				bloom_mat.emission_enabled = true
				bloom_mat.emission_energy_multiplier = 2.8
		if is_instance_valid(heart_tree_light):
			heart_tree_light.light_energy = 4.5
	for seed_id in collected_veilwood_seeds:
		if veilwood_seed_objects.has(seed_id):
			var seed_node: MeshInstance3D = veilwood_seed_objects[seed_id]
			if is_instance_valid(seed_node):
				seed_node.queue_free()
			veilwood_seed_objects.erase(seed_id)
	for id in collected:
		if crystal_objects.has(id):
			var entry: Dictionary = crystal_objects[id]
			if is_instance_valid(entry["node"]):
				entry["node"].queue_free()
			crystal_objects.erase(id)
	refresh_hud()
	show_message("Saved progress loaded.")
