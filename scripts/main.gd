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
var checkpoint_positions: Array[Vector3] = []
var active_checkpoint_index := -1
var bonus_shards := 0
var collected_bonus_shards: Array[String] = []
var bonus_shard_objects: Dictionary = {}

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
	mesh.radial_segments = 8
	mesh.rings = 4
	item.mesh = mesh
	item.position = pos
	item.scale = size
	var rock_mat := material(color, 0.94)
	rock_mat.metallic = 0.04
	item.material_override = rock_mat
	item.rotation = Vector3(float(seed_value % 5) * 0.09, float(seed_value % 7) * 0.31, float(seed_value % 3) * 0.07)
	parent.add_child(item)
	return item

func add_cliff_formation(pos: Vector3, scale_value: float, seed_value: int) -> void:
	# Layered faceted boulders create a stronger authored cliff silhouette than a
	# single primitive, while remaining cheap enough for the PSP-oriented target.
	var tones := [Color("#4a526d"), Color("#59627c"), Color("#68718a")]
	for i in range(4):
		var angle := float(i) * 1.57 + float(seed_value % 3) * 0.2
		var offset := Vector3(cos(angle) * scale_value * 0.48, float(i % 2) * scale_value * 0.28, sin(angle) * scale_value * 0.48)
		var rock := add_rock(self, pos + offset, Vector3(scale_value * (0.9 + float(i % 2) * 0.18), scale_value * (1.0 + float(i % 3) * 0.16), scale_value * 0.72), tones[i % tones.size()], seed_value + i * 7)
		rock.rotation.x += float(i % 2) * 0.11
	var cap := add_rock(self, pos + Vector3(0, scale_value * 1.15, 0), Vector3(scale_value * 0.9, scale_value * 0.48, scale_value * 0.8), Color("#707b91"), seed_value + 19)
	cap.rotation.z = -0.08 + float(seed_value % 4) * 0.04

func add_checkpoint_marker(pos: Vector3, marker_name: String) -> void:
	checkpoint_positions.append(pos)
	var ring := MeshInstance3D.new()
	ring.name = marker_name.replace(" ", "")
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.52
	mesh.outer_radius = 0.68
	ring.mesh = mesh
	ring.position = pos + Vector3(0, 0.06, 0)
	ring.rotation.x = PI * 0.5
	var glow_mat := material(Color("#83f4df"), 0.25)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color("#50e7dd")
	glow_mat.emission_energy_multiplier = 1.25
	ring.material_override = glow_mat
	add_child(ring)
	add_crystal_shard(self, pos + Vector3(0, 0.55, 0), 0.7, Color("#83f4df"), 0.13)

func add_grass_tuft(parent: Node3D, pos: Vector3, scale_value: float, color: Color, seed_value: int) -> MeshInstance3D:
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
	# Authored cliff clusters frame the valley and give the raised routes stronger silhouettes.
	for data in [[Vector3(-43, 1.4, -17), 3.2, 11], [Vector3(43, 1.6, -20), 3.5, 17], [Vector3(-41, 2.4, 28), 3.7, 23], [Vector3(41, 2.7, 29), 4.0, 29], [Vector3(-15, 2.0, -39), 3.0, 37], [Vector3(16, 2.2, -41), 3.3, 43]]:
		add_cliff_formation(data[0], float(data[1]), int(data[2]))
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
	for i in range(72):
		var gx := float(((i * 17) % 83) - 41)
		var gz := float(((i * 29) % 87) - 43)
		if absf(gx) < 5.0 and gz > -2.0 and gz < 13.0:
			continue
		if absf(gx) < 9.0 and gz > 10.0 and gz < 20.0:
			continue
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
	var bonus_positions: Array[Vector3] = [Vector3(-31, 3.0, -27), Vector3(32, 3.2, -29), Vector3(-27, 5.0, -36)]
	for i in range(bonus_positions.size()):
		var shard_id := "moonshard_%02d" % i
		if collected_bonus_shards.has(shard_id):
			continue
		var shard := add_crystal_shard(self, bonus_positions[i], 1.05, Color("#f4baff"), 0.3)
		shard.name = shard_id
		var shard_mat := shard.material_override as StandardMaterial3D
		if shard_mat:
			shard_mat.emission_enabled = true
			shard_mat.emission = Color("#db91ff")
			shard_mat.emission_energy_multiplier = 2.2
		bonus_shard_objects[shard_id] = {"node": shard, "base": bonus_positions[i], "phase": float(i) * 2.1}
