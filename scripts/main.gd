extends Node3D

const SAVE_PATH := "user://nightbound_save.json"
const AudioDirectorScript = preload("res://scripts/audio_director.gd")
const GLIDE_MAX_STAMINA := 2.8
var glide_stamina := 0.0
var glide_active := false
var checkpoint_position := Vector3(0, 1.5, 3)
var audio_director: Node
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
var veilwood_mote_bases: Array[Vector3] = []
var hero_wing_pivots: Array[Node3D] = []
var hero_body_visual: MeshInstance3D
var hero_head_visual: MeshInstance3D
var animated_grass: Array[MeshInstance3D] = []
var glide_bar: ProgressBar
var glide_bar_label: Label

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

func add_grass_tuft(parent: Node3D, pos: Vector3, scale_value: float, color: Color, seed_value: int) -> MeshInstance3D:
	# Three crossed, tapered blades give the ground a readable silhouette without
	# relying on more sphere-shaped placeholder bushes.
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var blade_angles := [0.0, 1.047, 2.094]
	for angle_index in range(blade_angles.size()):
		var angle: float = blade_angles[angle_index] + float(seed_value % 5) * 0.11
		var forward := Vector3(cos(angle), 0.0, sin(angle))
		var side_axis := Vector3(-forward.z, 0.0, forward.x)
		var base := vertices.size()
		var half_width := scale_value * (0.12 if angle_index == 1 else 0.16)
		var height := scale_value * (0.72 + float((seed_value + angle_index) % 4) * 0.12)
		var tip := forward * scale_value * 0.18 + Vector3(0, height, 0)
		vertices.append(-side_axis * half_width)
		vertices.append(side_axis * half_width)
		vertices.append(tip)
		indices.append_array(PackedInt32Array([base, base + 1, base + 2]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var tuft_mesh := ArrayMesh.new()
	tuft_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var tuft := MeshInstance3D.new()
	tuft.name = "MoonlitGrassTuft"
	tuft.mesh = tuft_mesh
	tuft.position = pos
	var tuft_mat := material(color, 0.92)
	tuft_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tuft_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	tuft.material_override = tuft_mat
	parent.add_child(tuft)
	animated_grass.append(tuft)
	return tuft

func add_wing_membrane(parent: Node3D, side: float) -> void:
	var mesh_instance := MeshInstance3D.new()
	var wing_mesh := ArrayMesh.new()
	var vertices := PackedVector3Array([Vector3(side * 0.28, 0.30, 0.02), Vector3(side * 1.48, 0.18, 0.02), Vector3(side * 1.18, -0.18, 0.02), Vector3(side * 0.92, -0.02, 0.02), Vector3(side * 0.66, -0.30, 0.02), Vector3(side * 0.42, -0.04, 0.02)])
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
	audio_director = AudioDirectorScript.new()
	audio_director.name = "AudioDirector"
	add_child(audio_director)
	if current_realm == "The Veilwood":
		audio_director.call("play_track", "veilwood_level_2")
	else:
		audio_director.call("play_track", "moonlit_valley_level_1")
	show_message("Explore the valley. Press E to reveal hidden echoes.")

func build_world() -> void:
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
	add_solid_box(Vector3(0, -0.5, 0), Vector3(100, 1, 100), Color("#416b43"))
	for p in [Vector3(-12, 0.4, -9), Vector3(11, 1.2, -14), Vector3(17, 0.4, 9), Vector3(-17, 3.2, 13), Vector3(-30, 1.0, -20), Vector3(-38, 2.4, -28), Vector3(-27, 3.8, -36), Vector3(28, 1.0, -22), Vector3(38, 2.5, -32), Vector3(31, 4.0, -40), Vector3(-31, 1.0, 24), Vector3(-39, 2.6, 34), Vector3(-27, 4.0, 40), Vector3(29, 1.0, 25), Vector3(39, 2.8, 35), Vector3(27, 4.2, 42)]:
		add_solid_box(p, Vector3(8, 1.2, 8), Color("#668b58"))
	for p in [Vector3(-20, 0.1, -15), Vector3(-25, 0.5, -21), Vector3(-31, 1.5, -27), Vector3(20, 0.1, -16), Vector3(26, 0.5, -23), Vector3(32, 1.6, -29), Vector3(-20, 0.1, 17), Vector3(-26, 0.5, 24), Vector3(-32, 1.7, 30), Vector3(20, 0.1, 18), Vector3(26, 0.6, 25), Vector3(32, 1.8, 31)]:
		add_solid_box(p, Vector3(5, 0.6, 5), Color("#78965f"))
	add_solid_box(Vector3(0, -0.1, 15), Vector3(14, 0.15, 8), Color("#3e9bc2"))
	add_solid_box(Vector3(0, 0.1, 7), Vector3(2.5, 0.4, 9), Color("#9b7047"))
	for p in [Vector3(-44, 0.8, -5), Vector3(45, 0.8, 4), Vector3(-5, 0.8, 45), Vector3(5, 0.8, -45)]:
		add_rock(self, p, Vector3(2.5, 1.25, 2.0), Color("#697487"), int(abs(p.x + p.z)))
		var crown := add_sphere(self, p + Vector3(0, 2.0, 0), 2.6, Color("#286b48"))
		crown.scale = Vector3(1.0, 0.85, 1.0)
	for p in [Vector3(-24, 0.5, -19), Vector3(24, 0.5, -18), Vector3(27, 0.5, 18), Vector3(-26, 0.5, 22)]:
		add_rock(self, p, Vector3(1.5, 0.9, 1.25), Color("#6e7487"), int(abs(p.x + p.z)))
		add_box(self, p + Vector3(0, 2, 0), Vector3(0.45, 3, 0.45), Color("#76502e"))
		var crown := add_sphere(self, p + Vector3(0, 4, 0), 1.8, Color("#286b48"))
		crown.scale = Vector3(1.0, 1.25, 0.9)
	for i in range(18):
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := -42.0 + float(i) * 5.0
		var x := side * (43.0 + float(i % 3) * 2.5)
		var rock := add_rock(self, Vector3(x, 2.0 + float(i % 4) * 0.7, z), Vector3(3.8 + float(i % 3) * 0.55, 3.0 + float(i % 3) * 0.45, 3.0), Color("#343d59") if i % 2 == 0 else Color("#414967"), i)
		rock.rotation.z += 0.08 if i % 2 == 0 else -0.06
	for p in [Vector3(-18, 1.0, -30), Vector3(18, 1.0, -33), Vector3(-42, 3.0, 14), Vector3(42, 3.0, 15), Vector3(-12, 1.0, 38), Vector3(13, 1.0, 39)]:
		for k in range(3):
			var shard := add_crystal_shard(self, p + Vector3((float(k) - 1.0) * 0.65, 0.55 + float(k % 2) * 0.25, 0), 1.15 + float(k % 2) * 0.35, Color("#6eeaf4") if k != 1 else Color("#a88aff"), 0.28)
			shard.rotation.z = (float(k) - 1.0) * 0.12
	for p in [Vector3(-8, 0.1, -17), Vector3(8, 0.1, -20), Vector3(-18, 0.2, 8), Vector3(18, 0.2, 7), Vector3(-35, 1.2, -12), Vector3(35, 1.2, -12), Vector3(-35, 1.3, 18), Vector3(35, 1.3, 18), Vector3(-15, 0.2, 32), Vector3(15, 0.2, 32)]:
		for part in range(3):
			var bush := add_sphere(self, p + Vector3((float(part) - 1.0) * 0.7, 0.35 + float(part % 2) * 0.2, 0), 0.85, Color("#315b46") if part != 1 else Color("#467452"))
			bush.scale = Vector3(1.25, 0.8, 1.0)
	# Small stylized grass clumps soften the hard edges between paths and valley floor.
	for i in range(72):
		var gx := float(((i * 17) % 83) - 41)
		var gz := float(((i * 29) % 87) - 43)
		if absf(gx) < 5.0 and gz > -2.0 and gz < 13.0:
			continue # Keep the spawn and bridge approach clear for gameplay readability.
		if absf(gx) < 9.0 and gz > 10.0 and gz < 20.0:
			continue # Preserve the moonlit pool silhouette.
		var grass_color := Color("#6d9b62") if i % 3 == 0 else (Color("#47785a") if i % 3 == 1 else Color("#8a9e69"))
		add_grass_tuft(self, Vector3(gx, 0.03, gz), 0.42 + float(i % 4) * 0.12, grass_color, i)
	for p in [Vector3(-4, 0, 5), Vector3(4, 0, 5), Vector3(-12, 0, -8), Vector3(-27, 1.0, -22), Vector3(12, 0, -12), Vector3(27, 1.0, -24), Vector3(-27, 1.0, 25), Vector3(27, 1.0, 26)]:
		add_lantern(p)
	for p in [Vector3(-22, 0.0, -5), Vector3(22, 0.0, -6), Vector3(-40, 1.0, 4), Vector3(40, 1.0, 5), Vector3(-20, 0.0, 30), Vector3(20, 0.0, 31), Vector3(-8, 0.0, 39), Vector3(8, 0.0, 40)]:
		var trunk := add_box(self, p + Vector3(0, 1.5, 0), Vector3(0.65, 3.0, 0.65), Color("#4d3b43"))
		trunk.rotation.z = randf_range(-0.08, 0.08)
		for crown in range(4):
			var offset := Vector3(randf_range(-0.75, 0.75), 2.7 + float(crown) * 0.55, randf_range(-0.45, 0.45))
			var foliage := add_sphere(self, p + offset, 1.15 - float(crown) * 0.12, Color("#244b48") if crown % 2 == 0 else Color("#315d53"))
			foliage.scale = Vector3(1.0, 1.25, 0.9)
	for side in [-1.0, 1.0]:
		add_box(self, Vector3(side * 1.25, 0.65, 7), Vector3(0.14, 0.9, 9), Color("#68482f"))
		for z in [3.5, 5.5, 7.5, 9.5, 11.0]:
			add_box(self, Vector3(side * 1.25, 1.05, z), Vector3(0.22, 1.7, 0.22), Color("#815c3b"))
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
	portal_core_node = add_sphere(self, Vector3(0, 2.7, -18.05), 1.35, Color("#342c58"))
	portal_core_node.scale = Vector3(0.88, 1.2, 0.18)
	portal_glow_light = OmniLight3D.new()
	portal_glow_light.name = "RealmGateCoreLight"
	portal_glow_light.position = Vector3(0, 2.8, -16.8)
	portal_glow_light.light_color = Color("#9c75ff")
	portal_glow_light.light_energy = 0.25
	portal_glow_light.omni_range = 7.0
	add_child(portal_glow_light)
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
	var crystal_positions: Array[Vector3] = [Vector3(-5, 1.0, -5), Vector3(7, 1.5, -12), Vector3(-14, 1.2, -10), Vector3(-25, 1.5, -21), Vector3(-38, 3.2, -29), Vector3(25, 1.5, -23), Vector3(38, 3.4, -33), Vector3(-25, 1.5, 24), Vector3(-38, 3.5, 35), Vector3(25, 1.6, 25), Vector3(38, 3.7, 36)]
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
	add_solid_box(Vector3(130, -0.5, 0), Vector3(76, 1, 76), Color("#252d50"))
	for p in [Vector3(118, 0.2, -8), Vector3(126, 0.7, -14), Vector3(137, 1.3, -20), Vector3(146, 2.0, -26), Vector3(138, 0.6, 10), Vector3(149, 1.4, 18), Vector3(158, 2.0, 25)]:
		add_solid_box(p, Vector3(7, 0.8, 7), Color("#3c466f"))
	# Cool-toned grass tufts break up the large flat Veilwood floor while
	# leaving the moonstone trail and Moonseed routes easy to read.
	for i in range(48):
		var gx := 130.0 + float(((i * 13) % 67) - 33)
		var gz := float(((i * 23) % 67) - 33)
		if absf(gx - 130.0) < 4.0 and gz > -28.0 and gz < 29.0:
			continue
		var grass_color := Color("#426d75") if i % 3 == 0 else (Color("#4b6d85") if i % 3 == 1 else Color("#536b70"))
		add_grass_tuft(self, Vector3(gx, 0.02, gz), 0.55 + float(i % 3) * 0.13, grass_color, 100 + i)
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
		veilwood_mote_bases.append(mote.position)
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
	heart_tree_light.light_energy = 1.0
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
	# A carved moonstone trail guides the player from the realm arrival point to the Heart-Tree.
	for i in range(9):
		var trail_z := 25.0 - float(i) * 6.2
		var trail_x := 130.0 + sin(float(i) * 0.72) * 2.0
		var trail_stone := add_rock(self, Vector3(trail_x, 0.18, trail_z), Vector3(2.5, 0.35, 2.0), Color("#555b83"), 40 + i)
		trail_stone.name = "VeilwoodTrailStone_%02d" % i
		var trail_rune := add_box(self, Vector3(trail_x, 0.39, trail_z), Vector3(0.9, 0.035, 0.12), Color("#79f2ef"))
		trail_rune.name = "VeilwoodTrailRune_%02d" % i
		var trail_mat := material(Color("#79f2ef"), 0.28)
		trail_mat.emission_enabled = true
		trail_mat.emission = Color("#62eaff")
		trail_mat.emission_energy_multiplier = 1.15
		trail_rune.material_override = trail_mat
	# The arrival arch makes the new realm feel like a deliberate threshold, not an empty side platform.
	for side in [-1.0, 1.0]:
		var arch_pillar := add_rock(self, Vector3(130.0 + side * 5.0, 2.2, 32.0), Vector3(1.0, 2.8, 0.9), Color("#4c456b"), int(side + 8))
		arch_pillar.name = "VeilwoodArrivalPillar"
		var arch_crystal := add_crystal_shard(self, Vector3(130.0 + side * 5.0, 4.5, 32.0), 1.3, Color("#8af5f0"), 0.28)
		arch_crystal.rotation.z = side * -0.16
	add_box(self, Vector3(130, 5.0, 32.0), Vector3(10.5, 0.55, 0.85), Color("#51466f"))
	for side in [-1.0, 1.0]:
		var arch_rune := add_box(self, Vector3(130.0 + side * 5.0, 2.3, 31.48), Vector3(0.13, 1.8, 0.08), Color("#8af5f0"))
		var arch_mat := material(Color("#8af5f0"), 0.25)
		arch_mat.emission_enabled = true
		arch_mat.emission = Color("#68eaff")
		arch_mat.emission_energy_multiplier = 1.4
		arch_rune.material_override = arch_mat

func make_crystal(pos: Vector3, id: String) -> void:
	var node := add_crystal_shard(self, pos, 1.6, Color("#68e9ff"), 0.38)
	node.name = id
	crystal_objects[id] = {"node": node, "base": pos, "phase": float(id.hash() % 100)}

func build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "NightboundBat"
	player.position = Vector3(0, 1.5, 3)
	add_child(player)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.45
	collision.shape = capsule
	collision.position = Vector3(0, 0.15, 0)
	player.add_child(collision)
	hero_body_visual = add_sphere(player, Vector3(0, 0.25, 0), 0.55, Color("#2e243b"))
	hero_body_visual.scale = Vector3(0.78, 1.15, 0.75)
	hero_head_visual = add_sphere(player, Vector3(0, 0.95, -0.02), 0.48, Color("#3b2b47"))
	hero_head_visual.scale = Vector3(0.9, 0.95, 0.9)
	for side in [-1.0, 1.0]:
		var ear := add_sphere(player, Vector3(side * 0.28, 1.3, -0.02), 0.28, Color("#493258"))
		ear.scale = Vector3(0.7, 1.45, 0.55)
	var eye_left := add_sphere(player, Vector3(-0.17, 1.04, -0.39), 0.085, Color("#d5a6ff"))
	var eye_right := add_sphere(player, Vector3(0.17, 1.04, -0.39), 0.085, Color("#d5a6ff"))
	# Emissive eyes remain readable against the dark fur without washing out the face.
	for eye in [eye_left, eye_right]:
		var eye_mat := eye.material_override as StandardMaterial3D
		if eye_mat:
			eye_mat.emission_enabled = true
			eye_mat.emission = Color("#b878ff")
			eye_mat.emission_energy_multiplier = 0.85
		var glint := add_sphere(player, eye.position + Vector3(-0.018, 0.025, -0.065), 0.022, Color("#fff0ff"))
		glint.name = "EyeGlint"
	var muzzle := add_sphere(player, Vector3(0, 0.82, -0.39), 0.22, Color("#624258"))
	muzzle.scale = Vector3(1.2, 0.7, 0.8)
	# Small facial accents help the hero read clearly at gameplay distance.
	var nose := add_sphere(player, Vector3(0, 0.84, -0.585), 0.055, Color("#f0a0c5"))
	nose.scale = Vector3(1.2, 0.8, 0.75)
	for side in [-1.0, 1.0]:
		var cheek := add_sphere(player, Vector3(side * 0.245, 0.82, -0.50), 0.065, Color("#8c526f"))
		cheek.scale = Vector3(1.15, 0.55, 0.35)
		var inner_ear := add_sphere(player, Vector3(side * 0.285, 1.34, -0.075), 0.105, Color("#c77fa9"))
		inner_ear.scale = Vector3(0.65, 1.2, 0.25)
	# A soft chest tuft breaks up the torso silhouette without adding a heavy model.
	for tuft in range(3):
		var fur := add_sphere(player, Vector3((float(tuft) - 1.0) * 0.12, 0.12 - absf(float(tuft) - 1.0) * 0.035, -0.405), 0.105, Color("#8b6b91"))
		fur.scale = Vector3(0.8, 1.25, 0.55)
	for side in [-1.0, 1.0]:
		# Animate each membrane and its arm together for a readable wing silhouette.
		var wing_pivot := Node3D.new()
		wing_pivot.name = "LeftWingPivot" if side < 0.0 else "RightWingPivot"
		player.add_child(wing_pivot)
		add_wing_membrane(wing_pivot, side)
		var wing_arm := add_box(wing_pivot, Vector3(side * 0.75, 0.35, 0.02), Vector3(0.12, 0.12, 1.55), Color("#241c2f"))
		wing_arm.rotation.z = side * 0.55
		# Fine muted-violet ribs make the membrane read as a designed bat wing.
		var main_rib := add_box(wing_pivot, Vector3(side * 0.82, 0.19, -0.015), Vector3(1.05, 0.035, 0.035), Color("#76518c"))
		main_rib.rotation.z = side * -0.10
		var rib_a := add_box(wing_pivot, Vector3(side * 0.68, 0.025, -0.018), Vector3(0.62, 0.025, 0.025), Color("#654477"))
		rib_a.rotation.z = side * -0.23
		var rib_b := add_box(wing_pivot, Vector3(side * 0.62, -0.105, -0.018), Vector3(0.42, 0.025, 0.025), Color("#654477"))
		rib_b.rotation.z = side * -0.34
		hero_wing_pivots.append(wing_pivot)
	for side in [-1.0, 1.0]:
		var foot := add_sphere(player, Vector3(side * 0.22, -0.43, -0.12), 0.14, Color("#b77a86"))
		foot.scale = Vector3(1.0, 0.55, 1.35)
		for toe in range(3):
			var claw := add_sphere(player, Vector3(side * 0.22 + (float(toe) - 1.0) * 0.09, -0.47, -0.25), 0.045, Color("#e0c6d0"))
			claw.scale = Vector3(0.75, 0.65, 1.2)
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
	glide_bar_label = Label.new()
	glide_bar_label.position = Vector2(22, 151)
	glide_bar_label.text = "GLIDE ENERGY"
	glide_bar_label.add_theme_font_size_override("font_size", 12)
	glide_bar_label.add_theme_color_override("font_color", Color("#c9c4ff"))
	layer.add_child(glide_bar_label)
	glide_bar = ProgressBar.new()
	glide_bar.position = Vector2(22, 172)
	glide_bar.size = Vector2(220, 16)
	glide_bar.min_value = 0.0
	glide_bar.max_value = GLIDE_MAX_STAMINA
	glide_bar.value = GLIDE_MAX_STAMINA
	glide_bar.show_percentage = false
	var bar_background := StyleBoxFlat.new()
	bar_background.bg_color = Color("#25263e")
	bar_background.corner_radius_top_left = 4
	bar_background.corner_radius_top_right = 4
	bar_background.corner_radius_bottom_left = 4
	bar_background.corner_radius_bottom_right = 4
	glide_bar.add_theme_stylebox_override("background", bar_background)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("#9b8cff")
	bar_fill.corner_radius_top_left = 4
	bar_fill.corner_radius_top_right = 4
	bar_fill.corner_radius_bottom_left = 4
	bar_fill.corner_radius_bottom_right = 4
	glide_bar.add_theme_stylebox_override("fill", bar_fill)
	layer.add_child(glide_bar)
	refresh_hud()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3(input.x, 0, input.y)
	if dir.length() > 0.05:
		player.rotation.y = atan2(-dir.x, -dir.z)
	if not player.is_on_floor():
		glide_active = Input.is_action_pressed("jump") and player.velocity.y < 0.5 and glide_stamina < GLIDE_MAX_STAMINA
		if glide_active:
			glide_stamina = minf(glide_stamina + delta, GLIDE_MAX_STAMINA)
			# A controlled, slower descent and stronger air steering make the glide
			# feel deliberate without granting unlimited flight.
			player.velocity.y = maxf(player.velocity.y - 4.0 * delta, -2.4)
			if dir.length() > 0.05:
				player.velocity.x = move_toward(player.velocity.x, dir.x * move_speed * 1.18, 18.0 * delta)
				player.velocity.z = move_toward(player.velocity.z, dir.z * move_speed * 1.18, 18.0 * delta)
			else:
				player.velocity.x = move_toward(player.velocity.x, 0.0, 2.0 * delta)
				player.velocity.z = move_toward(player.velocity.z, 0.0, 2.0 * delta)
		else:
			player.velocity.x = dir.x * move_speed
			player.velocity.z = dir.z * move_speed
			player.velocity.y -= 24.0 * delta
	else:
		glide_active = false
		glide_stamina = 0.0
		player.velocity.x = dir.x * move_speed
		player.velocity.z = dir.z * move_speed
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
	if is_instance_valid(glide_bar):
		glide_bar.value = GLIDE_MAX_STAMINA - glide_stamina
		glide_bar.modulate = Color("#8df2d2") if glide_stamina < GLIDE_MAX_STAMINA * 0.65 else Color("#e6c8ff")
	if is_instance_valid(glide_bar_label):
		glide_bar_label.text = "GLIDE ENERGY  •  %d%%" % int(round((1.0 - glide_stamina / GLIDE_MAX_STAMINA) * 100.0))
	var ambience_time := float(Time.get_ticks_msec()) / 1000.0
	# The torso banks into turns and pitches into a glide; the head gently
	# counterbalances to keep the hero's face readable during aerial movement.
	if is_instance_valid(hero_body_visual):
		var flight_pitch := -0.16 if glide_active else (0.08 if not player.is_on_floor() else 0.0)
		hero_body_visual.rotation.x = lerpf(hero_body_visual.rotation.x, flight_pitch, minf(delta * 5.0, 1.0))
		hero_body_visual.rotation.z = lerpf(hero_body_visual.rotation.z, clampf(-player.velocity.x * 0.018, -0.16, 0.16), minf(delta * 4.0, 1.0))
		hero_body_visual.position.y = 0.25 + sin(ambience_time * (7.0 if glide_active else 2.4)) * (0.025 if glide_active else 0.012)
	if is_instance_valid(hero_head_visual):
		hero_head_visual.rotation.z = lerpf(hero_head_visual.rotation.z, clampf(player.velocity.x * 0.008, -0.07, 0.07), minf(delta * 5.0, 1.0))
	# Broad wing beats while gliding, faster flaps while falling, subtle idle flutter.
	var wing_rate := 8.5 if glide_active else (6.0 if not player.is_on_floor() else 2.2)
	var wing_amount := 0.34 if glide_active else (0.24 if not player.is_on_floor() else 0.075)
	for i in range(hero_wing_pivots.size()):
		var wing: Node3D = hero_wing_pivots[i]
		if is_instance_valid(wing):
			var side := -1.0 if i == 0 else 1.0
			wing.rotation.z = side * sin(ambience_time * wing_rate) * wing_amount
	# Gentle, offset wind motion gives both realms a living ground layer.
	for i in range(animated_grass.size()):
		var tuft: MeshInstance3D = animated_grass[i]
		if is_instance_valid(tuft):
			var phase := float(i) * 1.37
			tuft.rotation.x = sin(ambience_time * 1.15 + phase) * 0.055
			tuft.rotation.z = cos(ambience_time * 0.92 + phase * 0.8) * 0.075
	for i in range(veilwood_motes.size()):
		var mote: MeshInstance3D = veilwood_motes[i]
		if is_instance_valid(mote):
			var phase := float(i) * 1.73
			mote.position.y = veilwood_mote_bases[i].y + sin(ambience_time * 1.1 + phase) * 0.32
			mote.position.x = veilwood_mote_bases[i].x + cos(ambience_time * 0.55 + phase) * 0.12
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
			if is_instance_valid(audio_director):
				audio_director.call("play_track", "veilwood_level_2")
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
	if is_instance_valid(audio_director):
		audio_director.call("play_track", "veilwood_level_2" if current_realm == "The Veilwood" else "moonlit_valley_level_1")
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