extends Node3D

const SAVE_PATH := "user://nightbound_save.json"
const GLIDE_MAX := 2.8
const AudioDirectorScript = preload("res://scripts/audio_director.gd")
var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var realm_label: Label
var crystal_label: Label
var seed_label: Label
var shard_label: Label
var relic_label: Label
var gate_status_label: Label
var compass_needle: Label
var message: Label
var bar: ProgressBar
var audio_director: Node
var realm := "Moonlit Valley"
var crystals := 0
var moonshards := 0
var moonseeds := 0
var relics := 0
var echo_timer := 0.0
var collected_relics: Array[String] = []
var glide := 0.0
var checkpoint_position := Vector3(0,1.5,3)
var points: Array[Vector3] = []
var crystal_nodes: Array[MeshInstance3D] = []
var shard_nodes: Array[MeshInstance3D] = []
var seed_nodes: Array[MeshInstance3D] = []
var relic_nodes: Array[MeshInstance3D] = []
var collected_crystals: Array[String] = []
var collected_shards: Array[String] = []
var collected_seeds: Array[String] = []
var portal_open := false
var t := 0.0
var body_visual: MeshInstance3D
var head_visual: MeshInstance3D
var tail_visual: MeshInstance3D
var wings: Array[Node3D] = []
var mote_nodes: Array[MeshInstance3D] = []
var mote_origins: Array[Vector3] = []
var gate_runes: Array[MeshInstance3D] = []

func _ready() -> void:
	# Build the playable scene explicitly; the main scene only provides this root script.
	audio_director = AudioDirectorScript.new()
	audio_director.name = "AudioDirector"
	add_child(audio_director)
	# Restore IDs/checkpoint before constructing collectibles so saved pickups stay absent.
	load_game()
	build_valley()
	build_veilwood()
	build_player()
	build_camera()
	build_hud()
	audio_director.call("play_track", "veilwood_level_2" if realm == "The Veilwood" else "moonlit_valley_level_1")
	refresh_hud()
	print("NIGHTBOUND_SCENE_READY")

func mat(c:Color, r:=0.8)->StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=c; m.roughness=r; return m
func box(pos:Vector3,size:Vector3,c:Color,solid:=false)->MeshInstance3D:
	var n:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size; n.mesh=mesh; n.position=pos; n.material_override=mat(c); add_child(n)
	if solid:
		var b:=StaticBody3D.new(); b.position=pos; var cs:=CollisionShape3D.new(); var sh:=BoxShape3D.new(); sh.size=size; cs.shape=sh; b.add_child(cs); add_child(b); n.reparent(b)
	return n
func glowing_box(pos:Vector3,size:Vector3,c:Color)->MeshInstance3D:
	var n:=box(pos,size,c)
	var glow_material:=n.material_override as StandardMaterial3D
	glow_material.emission_enabled=true
	glow_material.emission=c
	glow_material.emission_energy_multiplier=.7
	return n
func set_gate_state(awake:bool)->void:
	var rune_color:=Color("#8df6df") if awake else Color("#a58df2")
	for rune in gate_runes:
		if not is_instance_valid(rune): continue
		var rune_material:=rune.material_override as StandardMaterial3D
		if rune_material:
			rune_material.albedo_color=rune_color
			rune_material.emission=rune_color
			rune_material.emission_energy_multiplier=1.65 if awake else .55
func build_distant_citadel()->void:
	# A stacked low-poly skyline gives the gate a destination to frame, rather than an empty horizon.
	box(Vector3(0,1.55,-41.0),Vector3(15.5,3.35,2.7),Color("#273858"))
	box(Vector3(0,3.3,-40.5),Vector3(6.0,4.2,3.5),Color("#35466f"))
	box(Vector3(0,5.3,-40.6),Vector3(2.9,4.6,2.5),Color("#46578b"))
	var tower_data:Array[Vector4]=[
		Vector4(-5.5,3.0,-42.0,5.1),Vector4(5.5,3.0,-42.0,5.1),
		Vector4(-8.5,1.8,-40.0,3.6),Vector4(8.5,1.8,-40.0,3.6),
		Vector4(-3.1,3.4,-39.7,6.5),Vector4(3.1,3.4,-39.7,6.5)
	]
	for tower_index in range(tower_data.size()):
		var tower:Vector4=tower_data[tower_index]
		var width:=1.25 if tower_index<4 else .9
		box(Vector3(tower.x,tower.y+tower.w*.5,tower.z),Vector3(width,tower.w,width),Color("#35466f") if tower_index%2==0 else Color("#43568a"))
		var cone:=MeshInstance3D.new()
		var cone_mesh:=CylinderMesh.new()
		cone_mesh.top_radius=.015
		cone_mesh.bottom_radius=width*.78
		cone_mesh.height=1.25 if tower_index<4 else 1.55
		cone_mesh.radial_segments=6
		cone.mesh=cone_mesh
		cone.position=Vector3(tower.x,tower.y+tower.w+(cone_mesh.height*.5),tower.z)
		cone.material_override=mat(Color("#6b70bd"),.72)
		add_child(cone)
		var spire:=glowing_box(Vector3(tower.x,tower.y+tower.w+cone_mesh.height+.18,tower.z),Vector3(.055,.42,.055),Color("#7de8f0"))
		# Narrow windows catch moonlight and visually link the skyline to the gate.
		for window_index in range(2):
			glowing_box(Vector3(tower.x-.23+float(window_index)*.46,tower.y+tower.w*.48,tower.z+width*.505),Vector3(.09,.55,.035),Color("#61cfe9"))
	for side in [-1.0,1.0]:
		box(Vector3(side*6.7,1.4,-39.8),Vector3(1.4,3.0,4.2),Color("#293b5e"))
	# The moon is a flattened sphere with a dark rim and understated surface marks.
	var moon_rim:=orb(self,Vector3(14.0,11.2,-50.9),4.8,Color("#536ba2"))
	moon_rim.scale=Vector3(1.0,1.0,.055)
	var moon:=orb(self,Vector3(14.0,11.2,-50.5),4.3,Color("#d3def6"))
	moon.scale=Vector3(1.0,1.0,.055)
	var moon_material:=moon.material_override as StandardMaterial3D
	moon_material.emission_enabled=true
	moon_material.emission=Color("#b4ccff")
	moon_material.emission_energy_multiplier=.34
	for mark_index in range(5):
		var mark:=orb(self,Vector3(12.5+float((mark_index*7)%5)*.6,10.4+float((mark_index*3)%4)*.52,-50.38),.28+float(mark_index%2)*.12,Color("#aebde1"))
		mark.scale=Vector3(1.0,1.0,.035)
	# Use normal mesh instances here: this stays compatible with Godot's dummy renderer in headless validation.
	for star_index in range(28):
		var sx:=float(((star_index*37)%93)-46)
		var sy:=8.0+float((star_index*17)%12)
		var sz:=-48.0-float((star_index*11)%8)
		var star:=orb(self,Vector3(sx,sy,sz),.025+float(star_index%3)*.012,Color("#b9d5ff"))
		var star_material:=star.material_override as StandardMaterial3D
		star_material.emission_enabled=true
		star_material.emission=Color("#b9d5ff")
		star_material.emission_energy_multiplier=.85
func bush_cluster(p:Vector3,size_value:float,main_color:Color)->void:
	# Overlapping faceted canopies create readable, layered shrubs at the edges of the route.
	var placements:Array[Vector3]=[Vector3(-.5,.42,0),Vector3(0,.62,-.12),Vector3(.52,.43,.04)]
	var colors:Array[Color]=[main_color,main_color.lightened(.12),main_color.darkened(.1)]
	for cluster_index in range(placements.size()):
		var canopy:=orb(self,p+placements[cluster_index]*size_value,.62*size_value,colors[cluster_index])
		canopy.scale=Vector3(1.15,.78,.95)
		var canopy_material:=canopy.material_override as StandardMaterial3D
		canopy_material.roughness=.94
func build_lantern(p:Vector3,size_value:float,light_color:Color)->void:
	# Warm lanterns give the cold blue scene a few authored focal points.
	box(p+Vector3(0,.13*size_value,0),Vector3(.62,.26,.62)*size_value,Color("#3c435a"))
	box(p+Vector3(0,.72*size_value,0),Vector3(.19,.95,.19)*size_value,Color("#4a405b"))
	box(p+Vector3(0,1.28*size_value,0),Vector3(.48,.44,.48)*size_value,Color("#3b4562"))
	var flame:=orb(self,p+Vector3(0,1.28*size_value,0),.17*size_value,light_color)
	var flame_material:=flame.material_override as StandardMaterial3D
	flame_material.emission_enabled=true
	flame_material.emission=light_color
	flame_material.emission_energy_multiplier=1.5
	box(p+Vector3(0,1.56*size_value,0),Vector3(.56,.12,.56)*size_value,Color("#5d4f65"))
	var light:=OmniLight3D.new()
	light.position=p+Vector3(0,1.3*size_value,0)
	light.light_color=light_color
	light.light_energy=1.1
	light.omni_range=6.0*size_value
	light.shadow_enabled=false
	add_child(light)
func build_shallow_pool(p:Vector3,radius_x:float,radius_z:float)->void:
	# Use standard primitive meshes for consistent renderer support in Godot Compatibility.
	var water:=MeshInstance3D.new()
	var water_mesh:=CylinderMesh.new()
	water_mesh.top_radius=1.0
	water_mesh.bottom_radius=1.0
	water_mesh.height=.025
	water_mesh.radial_segments=24
	water.mesh=water_mesh
	water.position=p
	water.scale=Vector3(radius_x,1.0,radius_z)
	var water_material:=StandardMaterial3D.new()
	water_material.albedo_color=Color(.1,.45,.72,.82)
	water_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.roughness=.22
	water_material.metallic=.16
	water_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	water_material.emission_enabled=true
	water_material.emission=Color("#164c7d")
	water_material.emission_energy_multiplier=.35
	water.material_override=water_material
	add_child(water)
	# Staggered luminous bars suggest ripples without relying on custom TorusMesh surfaces.
	for ripple_index in range(3):
		var ripple:=MeshInstance3D.new()
		var ripple_mesh:=BoxMesh.new()
		ripple_mesh.size=Vector3(radius_x*(.55+float(ripple_index)*.22),.018,.045)
		ripple.mesh=ripple_mesh
		ripple.position=p+Vector3(0,.035+float(ripple_index)*.003,(float(ripple_index)-1.0)*radius_z*.22)
		var ripple_material:=mat(Color("#4ec8dd"),.3)
		ripple_material.emission_enabled=true
		ripple_material.emission=Color("#248bbf")
		ripple_material.emission_energy_multiplier=.28
		ripple.material_override=ripple_material
		add_child(ripple)
func build_waterfall(p:Vector3,width:float,height:float)->void:
	# Thin translucent box ribbons are more reliable than custom QuadMesh surfaces across renderers.
	var fall:=MeshInstance3D.new()
	var fall_mesh:=BoxMesh.new()
	fall_mesh.size=Vector3(width,height,.025)
	fall.mesh=fall_mesh
	fall.position=p+Vector3(0,height*.5,0)
	var fall_material:=StandardMaterial3D.new()
	fall_material.albedo_color=Color(.28,.72,.9,.54)
	fall_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	fall_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	fall_material.emission_enabled=true
	fall_material.emission=Color("#229cda")
	fall_material.emission_energy_multiplier=.32
	fall.material_override=fall_material
	add_child(fall)
	for ribbon_index in range(2):
		var ribbon:=MeshInstance3D.new()
		var ribbon_mesh:=BoxMesh.new()
		ribbon_mesh.size=Vector3(width*(.11 if ribbon_index==0 else .07),height*.9,.04)
		ribbon.mesh=ribbon_mesh
		ribbon.position=p+Vector3((-.22 if ribbon_index==0 else .24)*width,height*.5,.02)
		var ribbon_material:=mat(Color("#8ee8f0"),.3)
		ribbon_material.emission_enabled=true
		ribbon_material.emission=Color("#63d8ed")
		ribbon_material.emission_energy_multiplier=.3
		ribbon.material_override=ribbon_material
		add_child(ribbon)
func build_moonlit_clouds()->void:
	# Low-poly cloud ribbons frame the moon/citadel without obscuring the main landmark.
	var cloud_centers:Array[Vector3]=[
		Vector3(-43,8.0,-53),Vector3(-34,6.5,-50),Vector3(-27,9.0,-56),
		Vector3(31,7.0,-54),Vector3(40,8.8,-51),Vector3(47,6.2,-55),
		Vector3(-47,12.0,-58),Vector3(43,11.2,-60)
	]
	for cloud_index in range(cloud_centers.size()):
		var center:Vector3=cloud_centers[cloud_index]
		var cloud_color:=Color("#273b64") if cloud_index%2==0 else Color("#344976")
		for lobe_index in range(3):
			var side_offset:float=(float(lobe_index)-1.0)*1.65
			var lift:float=float((cloud_index+lobe_index)%3)*.42
			var cloud:=orb(self,center+Vector3(side_offset,lift,0),1.35+float((cloud_index+lobe_index)%2)*.35,cloud_color.lightened(.04*float(lobe_index)))
			cloud.scale=Vector3(1.5,.52,.12)
			var cloud_material:=cloud.material_override as StandardMaterial3D
			cloud_material.roughness=.98
func build_crystal_cluster(p:Vector3,main_color:Color,size_value:float)->void:
	# Decorative crystal clusters brighten optional side routes without incrementing the pickup counter.
	for shard_index in range(5):
		var angle:=float(shard_index)*TAU/5.0
		var radius:=.38*size_value if shard_index>0 else 0.0
		var shard_scale:=Vector3(.78,.98,.78)*size_value if shard_index==0 else Vector3(.48,.68,.48)*size_value
		var shard_pos:=p+Vector3(cos(angle)*radius,-.12*float(shard_index%2),sin(angle)*radius)
		var shard:=gem(shard_pos,main_color if shard_index%2==0 else main_color.lightened(.18))
		shard.scale=shard_scale
		shard.rotation.y=angle
		var shard_material:=shard.material_override as StandardMaterial3D
		shard_material.emission_energy_multiplier=1.65 if shard_index==0 else 1.25
func build_crystal_grotto()->void:
	# Optional side-route landmark: a dark cave mouth, weathered stone surround and luminous crystal core.
	var cave_center:=Vector3(-24.0,0.0,1.4)
	box(cave_center+Vector3(0,1.35,-.28),Vector3(4.6,2.8,.5),Color("#101a35"))
	box(cave_center+Vector3(0,-.02,0),Vector3(5.6,.28,1.65),Color("#35485f"))
	# Chunky low-poly rock shoulders and lintel frame the opening as a cave, not a door.
	rock(cave_center+Vector3(-2.15,1.0,.02),Vector3(.85,1.35,.9),Color("#44536d"),107)
	rock(cave_center+Vector3(2.1,1.1,.06),Vector3(.82,1.3,.92),Color("#53647b"),109)
	rock(cave_center+Vector3(-1.45,2.5,.02),Vector3(1.25,.62,.95),Color("#4a5d77"),113)
	rock(cave_center+Vector3(0,2.82,-.02),Vector3(1.25,.55,.92),Color("#617087"),127)
	rock(cave_center+Vector3(1.45,2.48,.04),Vector3(1.15,.68,.88),Color("#3d4d68"),131)
	# Carved cool runes guide the eye to the hidden chamber.
	for side in [-1.0,1.0]:
		var rune:=glowing_box(cave_center+Vector3(side*1.72,1.25,.53),Vector3(.075,1.8,.055),Color("#58d9ee"))
		rune.rotation.z=side*.08
		for rune_index in range(3):
			glowing_box(cave_center+Vector3(side*(1.72-.13*float(rune_index%2)),.58+float(rune_index)*.48,.55),Vector3(.25,.055,.06),Color("#8be8ee"))
	# Oversized decorative crystals form a focal point inside the cave; they are not counted as pickups.
	var cave_crystal:=gem(cave_center+Vector3(-.48,.95,.02),Color("#5cdfff"))
	cave_crystal.scale=Vector3(.95,1.6,.8)
	cave_crystal.rotation.z=-.08
	var cave_crystal_two:=gem(cave_center+Vector3(.58,.72,.0),Color("#a08cff"))
	cave_crystal_two.scale=Vector3(.58,1.18,.62)
	cave_crystal_two.rotation.z=.18
	var cave_crystal_three:=gem(cave_center+Vector3(1.02,.47,.12),Color("#6be9ff"))
	cave_crystal_three.scale=Vector3(.38,.76,.42)
	cave_crystal_three.rotation.z=.25
	# Four raised stones suggest an optional approach without blocking the main central bridge.
	var approach:Array[Vector3]=[
		Vector3(-12.0,.25,3.4),Vector3(-16.0,.45,1.7),Vector3(-20.0,.7,.2),Vector3(-26.0,.95,.8)
	]
	for step_index in range(approach.size()):
		var stone_pos:Vector3=approach[step_index]
		var stone:=rock(stone_pos,Vector3(1.35,.28,1.05),Color("#526a7b") if step_index%2==0 else Color("#3c526b"),step_index+151)
		var stone_body:=StaticBody3D.new()
		stone_body.position=stone_pos
		add_child(stone_body)
		var stone_collision:=CollisionShape3D.new()
		var stone_shape:=BoxShape3D.new()
		stone_shape.size=Vector3(2.2,.55,1.75)
		stone_collision.shape=stone_shape
		stone_collision.position.y=.12
		stone_body.add_child(stone_collision)
		stone.reparent(stone_body)

func build_gate_detail()->void:
	# Layered stone footing, thin carved trim and emissive runes make the gate a real landmark.
	for side in [-1.0,1.0]:
		box(Vector3(side*2.22,.28,-18.05),Vector3(1.0,.56,1.35),Color("#3b405f"),true)
		var outer_trim:=glowing_box(Vector3(side*1.78,2.45,-18.57),Vector3(.11,3.85,.10),Color("#a58df2"))
		gate_runes.append(outer_trim)
		for mark_index in range(3):
			var rune:=glowing_box(Vector3(side*2.22,.9+float(mark_index)*1.15,-18.59),Vector3(.13,.24,.07),Color("#a58df2"))
			gate_runes.append(rune)
	var crown_trim:=glowing_box(Vector3(0,5.05,-18.56),Vector3(3.55,.11,.10),Color("#a58df2"))
	gate_runes.append(crown_trim)
	for shard_index in range(3):
		var shard:=orb(self,Vector3(0,5.34,-18.57),.13+float(shard_index%2)*.035,Color("#bfa8ff"))
		shard.position.x=float(shard_index-1)*.34
		var shard_material:=shard.material_override as StandardMaterial3D
		shard_material.emission_enabled=true
		shard_material.emission=Color("#a58df2")
		shard_material.emission_energy_multiplier=.9
		gate_runes.append(shard)
	if portal_open: set_gate_state(true)
func orb(parent:Node3D,pos:Vector3,r:float,c:Color)->MeshInstance3D:
	var n:=MeshInstance3D.new(); var mesh:=SphereMesh.new(); mesh.radius=r; mesh.height=r*2; mesh.radial_segments=8; mesh.rings=4; n.mesh=mesh; n.position=pos; n.material_override=mat(c,0.35); parent.add_child(n); return n
func gem(pos:Vector3,c:Color)->MeshInstance3D:
	var n:=MeshInstance3D.new(); var mesh:=CylinderMesh.new(); mesh.top_radius=.03; mesh.bottom_radius=.32; mesh.height=1.4; mesh.radial_segments=6; n.mesh=mesh; n.position=pos; var m:=mat(c,.2); m.emission_enabled=true; m.emission=c; m.emission_energy_multiplier=1.0; n.material_override=m; n.set_meta("float_origin",pos); n.set_meta("float_phase",float(abs(int(pos.x*13.0+pos.z*7.0))%31)*.2); add_child(n); return n
func rock(p:Vector3, size:Vector3, c:Color, seed:int)->MeshInstance3D:
	# Faceted low-poly boulder: irregular silhouette without a box-like outline.
	var n:=MeshInstance3D.new()
	var mesh:=SphereMesh.new()
	mesh.radial_segments=7
	mesh.rings=4
	mesh.radius=1.0
	mesh.height=2.0
	n.mesh=mesh
	n.position=p
	n.scale=size
	n.rotation_degrees=Vector3(float((seed*13)%19)-9.0,float(seed*47%360),float((seed*7)%17)-8.0)
	n.material_override=mat(c,.96)
	add_child(n)
	return n
func plateau(p:Vector3,size:Vector3,seed:int)->void:
	# Rounded low-poly platform with a darker exposed-stone skirt and a grass cap.
	var body:=StaticBody3D.new()
	body.position=p
	add_child(body)
	var collision:=CollisionShape3D.new()
	var collision_shape:=BoxShape3D.new()
	collision_shape.size=Vector3(size.x*.92,size.y+.12,size.z*.92)
	collision.shape=collision_shape
	collision.position.y=.06
	body.add_child(collision)
	var base:=MeshInstance3D.new()
	var base_mesh:=CylinderMesh.new()
	base_mesh.top_radius=1.0
	base_mesh.bottom_radius=1.08
	base_mesh.height=size.y
	base_mesh.radial_segments=7
	base.mesh=base_mesh
	base.scale=Vector3(size.x*.47,1.0,size.z*.47)
	base.rotation.y=float(seed%7)*.17
	base.material_override=mat(Color("#3b5267") if seed%2==0 else Color("#405a68"),.94)
	body.add_child(base)
	var cap:=MeshInstance3D.new()
	var cap_mesh:=CylinderMesh.new()
	cap_mesh.top_radius=1.0
	cap_mesh.bottom_radius=1.025
	cap_mesh.height=.16
	cap_mesh.radial_segments=7
	cap.mesh=cap_mesh
	cap.scale=Vector3(size.x*.465,1.0,size.z*.465)
	cap.position.y=size.y*.5+.025
	cap.rotation.y=float((seed*3)%7)*.11
	var top_shades:Array[Color]=[Color("#587c7a"),Color("#607f7c"),Color("#547771"),Color("#68847c")]
	cap.material_override=mat(top_shades[seed%top_shades.size()],.92)
	body.add_child(cap)
	# Three broad facets break up the uniform cliff edge without cluttering the landing area.
	for facet_index in range(3):
		var facet:=MeshInstance3D.new()
		var facet_mesh:=SphereMesh.new()
		facet_mesh.radial_segments=6
		facet_mesh.rings=3
		facet_mesh.radius=1.0
		facet_mesh.height=2.0
		facet.mesh=facet_mesh
		var angle:=float(facet_index)*TAU/3.0+float(seed%5)*.23
		facet.position=Vector3(cos(angle)*size.x*.34,-size.y*.24,sin(angle)*size.z*.34)
		facet.scale=Vector3(size.x*.11,size.y*.2,size.z*.13)
		facet.material_override=mat(Color("#293c53") if facet_index==0 else Color("#455e70"),.97)
		body.add_child(facet)
	if p.y>=2.0:
		# Hanging tapered rock spires make elevated routes read as floating islands.
		for root_index in range(3):
			var root_spire:=MeshInstance3D.new()
			var root_mesh:=CylinderMesh.new()
			root_mesh.top_radius=.035
			root_mesh.bottom_radius=.24+float(root_index%2)*.07
			root_mesh.height=1.15+float((seed+root_index)%3)*.28
			root_mesh.radial_segments=5
			root_spire.mesh=root_mesh
			var root_angle:=float(root_index)*TAU/3.0+float(seed%4)*.2
			root_spire.position=Vector3(cos(root_angle)*size.x*.22,-size.y*.5-root_mesh.height*.42,sin(root_angle)*size.z*.22)
			root_spire.rotation.z=cos(root_angle)*.12
			root_spire.material_override=mat(Color("#2e435b") if root_index==0 else Color("#40586c"),.98)
			body.add_child(root_spire)
	# Tiny grass blades sit near platform edges, leaving the center clear for landing.
	for tuft_index in range(3):
		var tuft:=MeshInstance3D.new()
		var tuft_mesh:=CylinderMesh.new()
		tuft_mesh.top_radius=.008
		tuft_mesh.bottom_radius=.055
		tuft_mesh.height=.28+float((seed+tuft_index)%3)*.06
		tuft_mesh.radial_segments=4
		tuft.mesh=tuft_mesh
		var side:float=-1.0 if tuft_index%2==0 else 1.0
		tuft.position=Vector3(side*size.x*.28,size.y*.5+.15,-size.z*.24+float(tuft_index)*size.z*.23)
		tuft.rotation.z=side*.18
		tuft.material_override=mat(Color("#568b75") if tuft_index%2==0 else Color("#6b9578"),.9)
		body.add_child(tuft)
func build_entry_bridge()->void:
	# Break the old plain plank into individual deck boards, inset runners and wayfinding lights.
	var board_colors:Array[Color]=[Color("#896b5c"),Color("#9b7964"),Color("#806454")]
	for board_index in range(6):
		var z_pos:=2.3+float(board_index)*1.48
		box(Vector3(0,.1,z_pos),Vector3(2.42,.4,1.34),board_colors[board_index%board_colors.size()],true)
		box(Vector3(-1.13,.315,z_pos),Vector3(.07,.045,1.22),Color("#5f7d88"))
		box(Vector3(1.13,.315,z_pos),Vector3(.07,.045,1.22),Color("#5f7d88"))
		if board_index%2==0:
			for side in [-1.0,1.0]:
				var stud:=orb(self,Vector3(side*.91,.36,z_pos),.065,Color("#8fe9e1"))
				var stud_material:=stud.material_override as StandardMaterial3D
				stud_material.emission_enabled=true
				stud_material.emission=Color("#71dcd6")
				stud_material.emission_energy_multiplier=1.05
func build_river_crossing()->void:
	# A visible east-west magical stream creates a genuine landscape break between spawn and the gate.
	var water:=MeshInstance3D.new()
	var water_mesh:=BoxMesh.new()
	water_mesh.size=Vector3(48.0,.025,6.4)
	water.mesh=water_mesh
	water.position=Vector3(0,.035,-11.8)
	var water_material:=StandardMaterial3D.new()
	water_material.albedo_color=Color(.045,.29,.48,.88)
	water_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	water_material.roughness=.2
	water_material.emission_enabled=true
	water_material.emission=Color("#0d477c")
	water_material.emission_energy_multiplier=.42
	water.material_override=water_material
	add_child(water)
	# Bright, broken stream streaks add direction without relying on custom mesh surfaces.
	for streak_index in range(11):
		var x_pos:float=-21.0+float(streak_index)*4.2
		if absf(x_pos)<3.4:
			continue
		var streak:=MeshInstance3D.new()
		var streak_mesh:=BoxMesh.new()
		streak_mesh.size=Vector3(1.5+float(streak_index%3)*.65,.016,.045)
		streak.mesh=streak_mesh
		streak.position=Vector3(x_pos,.06,-11.8+float((streak_index*3)%5)-2.0)
		streak.rotation.y=float(streak_index%3)*.08
		var streak_material:=mat(Color("#3ba8d4"),.22)
		streak_material.emission_enabled=true
		streak_material.emission=Color("#2082c2")
		streak_material.emission_energy_multiplier=.46
		streak.material_override=streak_material
		add_child(streak)
	# Broken, faceted banks frame the water and keep the traversal route open.
	for bank_side in [-1.0,1.0]:
		for bank_index in range(10):
			var x_pos:float=-22.0+float(bank_index)*4.8
			if absf(x_pos)<3.6:
				continue
			var z_pos:float=-11.8+bank_side*3.45
			var rock_size:=Vector3(1.2+float(bank_index%3)*.22,.42+float((bank_index+1)%3)*.16,.72+float(bank_index%2)*.24)
			rock(Vector3(x_pos,.12,z_pos),rock_size,Color("#354c63") if bank_index%2==0 else Color("#4c6477"),bank_index+int(bank_side*19))
			if bank_index%3==0:
				bush_cluster(Vector3(x_pos,.05,z_pos+bank_side*.25),.72,Color("#2e564b"))
	# Six solid deck boards form the bridge in the player's route across the stream.
	var deck_colors:Array[Color]=[Color("#745b55"),Color("#957667"),Color("#80635a")]
	for board_index in range(7):
		var z_pos:float=-8.85-float(board_index)*.86
		box(Vector3(0,.22,z_pos),Vector3(2.85,.34,.79),deck_colors[board_index%deck_colors.size()],true)
		for side in [-1.0,1.0]:
			box(Vector3(side*1.27,.405,z_pos),Vector3(.045,.035,.68),Color("#7adce1"))
	# Short, low rails and endpoint lantern-studs define the bridge silhouette but stay below wing height.
	for side in [-1.0,1.0]:
		for end_index in range(3):
			var z_pos:float=-8.72-float(end_index)*2.58
			box(Vector3(side*1.34,.58,z_pos),Vector3(.12,.78,.12),Color("#4b3d58"),true)
		box(Vector3(side*1.34,.79,-11.25),Vector3(.07,.08,5.05),Color("#654f65"))
		for end_z in [-8.72,-14.3]:
			var lamp:=orb(self,Vector3(side*1.1,.49,end_z),.075,Color("#86e8eb"))
			var lamp_material:=lamp.material_override as StandardMaterial3D
			lamp_material.emission_enabled=true
			lamp_material.emission=Color("#65dce7")
			lamp_material.emission_energy_multiplier=.9

func cliff(p:Vector3,s:float)->void:
	var shades:Array[Color]=[Color("#424d68"),Color("#53617d"),Color("#68758d"),Color("#3a455e"),Color("#778198")]
	for i in range(5):
		var angle:=float(i)*TAU/5.0
		var offset:=Vector3(cos(angle)*s*.42,float((i%3)-1)*s*.14,sin(angle)*s*.42)
		var size:=Vector3(s*(.56+float((i*3)%4)*.07),s*(.62+float((i*2)%3)*.12),s*(.5+float((i*5)%3)*.08))
		rock(p+offset,size,shades[(i+int(abs(p.x)))%shades.size()],i+int(abs(p.z)*3.0))
	# Thin broken ledges give the cliff a readable layered silhouette.
	for i in range(2):
		var ledge:=rock(p+Vector3((-.35 if i==0 else .32)*s,s*(.42+float(i)*.2),-.18*s),Vector3(s*.58,s*.13,s*.5),Color("#8290a2") if i==0 else Color("#39455e"),i+31)
		ledge.rotation.z=.12 if i==0 else -.16
func checkpoint(p:Vector3)->void:
	points.append(p); var r:=MeshInstance3D.new(); var tm:=TorusMesh.new(); tm.inner_radius=.5; tm.outer_radius=.68; r.mesh=tm; r.position=p+Vector3(0,.08,0); r.rotation.x=PI*.5; var m:=mat(Color("#83f4df"),.2); m.emission_enabled=true; m.emission=Color("#50e7dd"); m.emission_energy_multiplier=1.5; r.material_override=m; add_child(r)
func tree(p:Vector3,scale_value:=1.0,forest_color:=Color("#304a3b"))->void:
	var trunk:=MeshInstance3D.new(); var tm:=CylinderMesh.new(); tm.top_radius=.18*scale_value; tm.bottom_radius=.32*scale_value; tm.height=2.8*scale_value; tm.radial_segments=7; trunk.mesh=tm; trunk.position=p+Vector3(0,1.4*scale_value,0); trunk.material_override=mat(Color("#44374a"),.95); add_child(trunk)
	# Three offset canopy lobes give the tree a layered silhouette instead of a single round ball.
	var lobe_positions:Array[Vector3]=[Vector3(-.62,3.0,.03),Vector3(.62,3.08,-.04),Vector3(0,3.58,.08)]
	var lobe_scales:Array[Vector3]=[Vector3(.78,.82,.76),Vector3(.82,.78,.8),Vector3(.76,.72,.75)]
	var lobe_colors:Array[Color]=[forest_color,forest_color.lightened(.11),forest_color.darkened(.09)]
	for lobe_index in range(3):
		var lobe:=MeshInstance3D.new()
		var lobe_mesh:=SphereMesh.new()
		lobe_mesh.radius=1.0
		lobe_mesh.height=2.0
		lobe_mesh.radial_segments=8
		lobe_mesh.rings=4
		lobe.mesh=lobe_mesh
		lobe.position=p+lobe_positions[lobe_index]*scale_value
		lobe.scale=lobe_scales[lobe_index]*scale_value
		lobe.material_override=mat(lobe_colors[lobe_index],.94)
		add_child(lobe)
	# Small glowing fruit/lights across the canopy add readable magical accents.
	for glow_index in range(3):
		var glow:=orb(self,p+Vector3((float(glow_index)-1.0)*.56*scale_value,3.15*scale_value+float(glow_index%2)*.47*scale_value,.72*scale_value),.07*scale_value,Color("#83e6bd"))
		var glow_material:=glow.material_override as StandardMaterial3D
		glow_material.emission_enabled=true
		glow_material.emission=Color("#67dcae")
		glow_material.emission_energy_multiplier=.85
func grass_cluster(p:Vector3,scale_value:float,add_bloom:bool)->void:
	# Three individually angled low-poly blades make small readable vegetation clumps.
	var blade_colors:Array[Color]=[Color("#56866b"),Color("#76a77d"),Color("#8bb58c")]
	for blade_index in range(3):
		var blade:=MeshInstance3D.new()
		var blade_mesh:=CylinderMesh.new()
		blade_mesh.top_radius=.006
		blade_mesh.bottom_radius=.045*scale_value
		blade_mesh.height=.3*scale_value+float(blade_index%2)*.07*scale_value
		blade_mesh.radial_segments=4
		blade.mesh=blade_mesh
		var angle:=float(blade_index)*TAU/3.0
		blade.position=p+Vector3(cos(angle)*.09*scale_value,.16*scale_value,sin(angle)*.09*scale_value)
		blade.rotation.z=cos(angle)*.28
		blade.rotation.x=sin(angle)*.24
		blade.material_override=mat(blade_colors[blade_index],.95)
		add_child(blade)
	if add_bloom:
		var bloom:=orb(self,p+Vector3(0,.29*scale_value,0),.055*scale_value,Color("#a5e6ee"))
		var bloom_material:=bloom.material_override as StandardMaterial3D
		bloom_material.emission_enabled=true
		bloom_material.emission=Color("#82d9e8")
		bloom_material.emission_energy_multiplier=.65
func apply_moonlit_ground_material(ground:MeshInstance3D)->void:
	# World-space procedural mottling gives the broad ground plane layered moss/stone variation.
	var ground_shader:=Shader.new()
	ground_shader.code="""shader_type spatial;
	render_mode diffuse_burley, specular_schlick_ggx;
	varying vec3 v_world_position;
	float hash21(vec2 p) {
		p = fract(p * vec2(123.34, 456.21));
		p += dot(p, p + 45.32);
		return fract(p.x * p.y);
	}
	float value_noise(vec2 p) {
		vec2 cell = floor(p);
		vec2 f = fract(p);
		f = f * f * (3.0 - 2.0 * f);
		float a = hash21(cell);
		float b = hash21(cell + vec2(1.0, 0.0));
		float c = hash21(cell + vec2(0.0, 1.0));
		float d = hash21(cell + vec2(1.0, 1.0));
		return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
	}
	void vertex() {
		v_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	}
	void fragment() {
		vec2 p = v_world_position.xz;
		float broad = value_noise(p * 0.075);
		float mid = value_noise(p * 0.24 + vec2(13.0, 7.0));
		float fine = value_noise(p * 0.82 + vec2(4.0, 19.0));
		float moss_mask = smoothstep(0.40, 0.60, broad * 0.68 + mid * 0.32);
		float stone_speckle = smoothstep(0.59, 0.86, fine);
		vec3 deep_stone = vec3(0.028, 0.060, 0.095);
		vec3 blue_stone = vec3(0.095, 0.175, 0.235);
		vec3 moss = vec3(0.075, 0.205, 0.125);
		vec3 color = mix(deep_stone, blue_stone, 0.18 + mid * 0.64);
		color = mix(color, moss, moss_mask * 0.82);
		color = mix(color, color * vec3(0.58, 0.68, 0.74), stone_speckle * 0.26);
		ALBEDO = color;
		ROUGHNESS = 0.94;
		METALLIC = 0.0;
	}
	"""
	var ground_material:=ShaderMaterial.new()
	ground_material.shader=ground_shader
	ground.material_override=ground_material

func build_valley_ground_detail()->void:
	# Keep a clear central traversal corridor while adding foreground and side-plane texture.
	var rock_colors:Array[Color]=[Color("#435968"),Color("#536979"),Color("#384d5e"),Color("#617582")]
	for i in range(34):
		var x_pos:=float(((i*29)%79)-39)
		if absf(x_pos)<11.0:
			x_pos=signf(x_pos)*12.0
		var z_pos:=float(((i*37)%83)-41)
		var size:=Vector3(.78+float(i%4)*.18,.27+float(i%3)*.1,.62+float((i*3)%4)*.15)
		rock(Vector3(x_pos,.08,z_pos),size,rock_colors[i%rock_colors.size()],i+83)
	for i in range(100):
		var x_pos:=float(((i*23)%87)-43)
		var z_pos:=float(((i*31)%87)-43)
		# Preserve clear landing space around the entry bridge and the primary route.
		if absf(x_pos)<9.0 and z_pos>-23.0 and z_pos<14.0:
			continue
		if absf(x_pos)<5.0 and absf(z_pos+18.0)<8.0:
			continue
		grass_cluster(Vector3(x_pos,.015,z_pos),1.0+float(i%4)*.2,i%7==0)
func build_motes(center_x:float,count:int,radius:float,glow_color:Color)->void:
	for i in range(count):
		var angle:=float(i)*2.399963
		var ring:=radius*(.28+float((i*7)%17)/22.0)
		var p:=Vector3(center_x+cos(angle)*ring,.7+float((i*11)%19)*.19,sin(angle)*ring)
		var mote:=orb(self,p,.045+float(i%3)*.018,glow_color)
		var material:=mote.material_override as StandardMaterial3D
		material.emission_enabled=true; material.emission=glow_color; material.emission_energy_multiplier=1.4
		mote_nodes.append(mote); mote_origins.append(p)
func build_valley()->void:
	build_motes(0,24,38,Color("#9ce9d9"))
	var w:=WorldEnvironment.new(); var e:=Environment.new(); e.background_mode=Environment.BG_COLOR; e.background_color=Color("#10182d"); e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color=Color("#8195cf"); e.ambient_light_energy=.42; e.fog_enabled=true; e.fog_density=.012; e.fog_light_color=Color("#252d49"); e.fog_light_energy=.78; w.environment=e; add_child(w)
	var light:=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-48,-32,0); light.light_color=Color("#b8ccff"); light.light_energy=1.15; light.shadow_enabled=true; add_child(light)
	var main_ground:=box(Vector3(0,-.5,0),Vector3(100,1,100),Color("#2f4d49"),true)
	apply_moonlit_ground_material(main_ground)
	var platform_positions:Array[Vector3]=[Vector3(-12,.4,-9),Vector3(11,1.2,-14),Vector3(17,.4,9),Vector3(-17,3.2,13),Vector3(-30,1,-20),Vector3(-38,2.4,-28),Vector3(-27,3.8,-36),Vector3(28,1,-22),Vector3(38,2.5,-32),Vector3(31,4,-40),Vector3(-31,1,24),Vector3(-39,2.6,34),Vector3(-27,4,40),Vector3(29,1,25),Vector3(39,2.8,35),Vector3(27,4.2,42)]
	for platform_index in range(platform_positions.size()):
		plateau(platform_positions[platform_index],Vector3(8,1.2,8),platform_index)
	for p in [Vector3(-43,1.4,-17),Vector3(43,1.6,-20),Vector3(-41,2.4,28),Vector3(41,2.7,29),Vector3(-15,2,-39),Vector3(16,2.2,-41)]: cliff(p,3.3)
	for p in [Vector3(-46,2.7,-34),Vector3(46,3.0,-36),Vector3(-45,1.8,2),Vector3(45,2.0,-3)]: cliff(p,4.0)
	for p in [Vector3(-21,0,-4),Vector3(18,0,-7),Vector3(-33,0,8),Vector3(34,0,8),Vector3(-12,0,31),Vector3(15,0,34),Vector3(-40,0,-7),Vector3(41,0,-8)]: tree(p,1.15,Color("#31533f"))
	for p in [Vector3(-8,0,10),Vector3(8,0,14),Vector3(-22,0,16),Vector3(22,0,18)]: tree(p,.72,Color("#3e6247"))
	# Side woodland layers frame the traversal corridor while leaving the stream and bridge visible.
	for side_tree_index in range(12):
		var side:float=-1.0 if side_tree_index%2==0 else 1.0
		var row_index:=side_tree_index/2
		var tree_z:=22.0-float(row_index)*5.0
		var tree_x:=side*(27.0+float(side_tree_index%3)*4.6)
		var tree_color:=Color("#294f42") if side_tree_index%2==0 else Color("#365b4b")
		tree(Vector3(tree_x,0,tree_z),1.05+float(side_tree_index%3)*.18,tree_color)
	build_entry_bridge()
	build_river_crossing()
	build_valley_ground_detail()
	build_crystal_cluster(Vector3(-23,.85,-4),Color("#62dcff"),1.15)
	build_crystal_cluster(Vector3(24,.85,-5),Color("#d492ff"),1.12)
	build_crystal_cluster(Vector3(-36,1.2,9),Color("#78e8ff"),1.4)
	build_crystal_cluster(Vector3(36,1.2,10),Color("#cf9aff"),1.35)
	var bush_positions:Array[Vector3]=[
		Vector3(-13,0.02,8),Vector3(13,0.02,8),Vector3(-19,0.02,5),Vector3(19,0.02,5),
		Vector3(-15,0.02,11),Vector3(15,0.02,11),Vector3(-19,0.02,11),Vector3(24,0.02,1),
		Vector3(-27,0.02,-3),Vector3(27,0.02,-3),Vector3(-20,0.02,-10),Vector3(20,0.02,-10)]
	for bush_index in range(bush_positions.size()):
		bush_cluster(bush_positions[bush_index],1.25+float(bush_index%3)*.22,Color("#285548") if bush_index%2==0 else Color("#345c4c"))
	var ps=[Vector3(-5,1,-5),Vector3(7,1.5,-12),Vector3(-14,1.2,-10),Vector3(-25,1.5,-21),Vector3(-38,3.2,-29),Vector3(25,1.5,-23),Vector3(38,3.4,-33),Vector3(-25,1.5,24),Vector3(-38,3.5,35),Vector3(25,1.6,25),Vector3(38,3.7,36)]
	for i in range(11):
		var id:="crystal_%02d"%i; if not collected_crystals.has(id): var n:=gem(ps[i],Color("#68e9ff")); n.name=id; crystal_nodes.append(n)
	var relic_positions: Array[Vector3]=[Vector3(-17,1.7,13),Vector3(17,2.0,17),Vector3(-39,4.0,35),Vector3(38,4.2,36),Vector3(-28,4.8,-36)]
	for i in range(relic_positions.size()):
		var relic_id:="relic_%02d"%i
		if not collected_relics.has(relic_id):
			var relic:=gem(relic_positions[i],Color("#f8d58b")); relic.name=relic_id; relic.visible=false
			var relic_material:=relic.material_override as StandardMaterial3D
			relic_material.emission_enabled=false
			relic_nodes.append(relic)
	var bonus_positions: Array[Vector3]=[Vector3(-31,3,-27),Vector3(32,3.2,-29),Vector3(-27,5,-36)]
	for i in range(3):
		var id:="moonshard_%02d"%i; if not collected_shards.has(id): var n:=gem(bonus_positions[i],Color("#f4baff")); n.name=id; shard_nodes.append(n)
	checkpoint(Vector3(0,1.5,3)); checkpoint(Vector3(-25,1.5,-21)); checkpoint(Vector3(25,1.5,-23))
	box(Vector3(-2.25,2.4,-18),Vector3(.75,4.8,1),Color("#45445f"),true); box(Vector3(2.25,2.4,-18),Vector3(.75,4.8,1),Color("#45445f"),true); box(Vector3(0,4.85,-18),Vector3(5.1,.75,1),Color("#56516e"),true)
	build_gate_detail()
	build_crystal_grotto()
	build_distant_citadel()
	build_moonlit_clouds()
	build_lantern(Vector3(-3.35,0,-16.6),.9,Color("#ffbf70"))
	build_lantern(Vector3(3.35,0,-16.6),.9,Color("#ffbf70"))
	build_lantern(Vector3(-1.75,0,8.0),.72,Color("#ffd18b"))
	build_lantern(Vector3(1.75,0,8.0),.72,Color("#ffd18b"))
	build_shallow_pool(Vector3(-30,.02,-12.0),4.5,4.0)
	build_shallow_pool(Vector3(28,.02,-14.0),4.2,3.6)
	build_waterfall(Vector3(-30,0,-16.0),2.6,1.55)
	build_waterfall(Vector3(28,0,-18.0),2.4,1.55)
	build_waterfall(Vector3(-38,0,-24.0),2.1,2.95)
	build_waterfall(Vector3(38,0,-28.0),2.1,3.25)
func build_veilwood()->void:
	build_motes(130,28,31,Color("#d5a1ff"))
	box(Vector3(130,-.5,0),Vector3(76,1,76),Color("#252d50"),true)
	for p in [Vector3(118,.2,-8),Vector3(126,.7,-14),Vector3(137,1.3,-20),Vector3(146,2,-26),Vector3(138,.6,10),Vector3(149,1.4,18),Vector3(158,2,25)]: box(p,Vector3(7,.8,7),Color("#3c466f"),true)
	for p in [Vector3(111,0,-13),Vector3(116,0,8),Vector3(151,0,-6),Vector3(158,0,14),Vector3(143,0,30),Vector3(117,0,29)]: tree(p,1.3,Color("#302b50"))
	for i in range(13):
		var side:=-1.0 if i%2==0 else 1.0; var p:=Vector3(130+side*(12+float(i%4)*5),0,-30+float(i)*5); box(p+Vector3(0,3,0),Vector3(.8,6,.8),Color("#37304f")); orb(self,p+Vector3(0,5,0),2,Color("#4c3679"))
	var seed_positions=[Vector3(111,1.1,-4),Vector3(143,1.4,-13),Vector3(155,2.1,23),Vector3(115,1.1,23),Vector3(130,1.4,-24)]
	for i in range(5):
		var id:="moonseed_%02d"%i; if not collected_seeds.has(id): var n:=gem(seed_positions[i],Color("#f0a8ff")); n.name=id; seed_nodes.append(n)
	checkpoint(Vector3(130,1.5,4)); checkpoint(Vector3(130,1.5,-24))
func make_bat_wing_mesh(side:float)->ArrayMesh:
	# A small fan of triangles forms a pointed bat wing with scalloped trailing edges.
	var vertices:=PackedVector3Array([
		Vector3(0.0,0.0,0.0),
		Vector3(.46,.24,0.0),
		Vector3(.40,-.10,0.0),
		Vector3(.91,.38,0.0),
		Vector3(.78,-.30,0.0),
		Vector3(1.48,.20,0.0),
		Vector3(1.19,-.12,0.0)
	])
	for vertex_index in range(vertices.size()):
		var vertex:=vertices[vertex_index]
		vertex.x*=side
		vertices[vertex_index]=vertex
	var indices:=PackedInt32Array([0,1,2,2,1,3,2,3,4,4,3,5,4,5,6])
	# Mirror triangle winding on the left wing so both membranes retain consistent front normals.
	if side<0.0:
		for triangle_index in range(0,indices.size(),3):
			var temp:=indices[triangle_index+1]
			indices[triangle_index+1]=indices[triangle_index+2]
			indices[triangle_index+2]=temp
	var normals:=PackedVector3Array()
	normals.resize(vertices.size())
	for normal_index in range(normals.size()):
		normals[normal_index]=Vector3(0,0,1)
	var arrays:Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_INDEX]=indices
	var wing_mesh:=ArrayMesh.new()
	wing_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return wing_mesh

func build_player()->void:
	player=CharacterBody3D.new(); player.name="NightboundBat"; player.position=checkpoint_position; add_child(player); var cs:=CollisionShape3D.new(); var cap:=CapsuleShape3D.new(); cap.radius=.42; cap.height=1.45; cs.shape=cap; player.add_child(cs)
	body_visual=orb(player,Vector3(0,.25,0),.55,Color("#2e243b")); body_visual.scale=Vector3(.78,1.15,.75); head_visual=orb(player,Vector3(0,.95,-.02),.48,Color("#3b2b47")); head_visual.scale=Vector3(.9,.95,.9)
	# A short muzzle, nose and chest bib make the face/body read more clearly from behind the camera.
	var muzzle:=orb(player,Vector3(0,.83,-.405),.19,Color("#71527d")); muzzle.scale=Vector3(.82,.58,.62)
	var nose:=orb(player,Vector3(0,.91,-.52),.055,Color("#f08bbf")); nose.scale=Vector3(1.15,.72,.65)
	var chest:=orb(player,Vector3(0,.28,-.365),.3,Color("#766184")); chest.scale=Vector3(.68,1.0,.22)
	# Ears give the bat a sharper silhouette at gameplay distance.
	for side in [-1.0,1.0]:
		var ear:=MeshInstance3D.new()
		var ear_mesh:=CylinderMesh.new()
		ear_mesh.top_radius=.015; ear_mesh.bottom_radius=.16; ear_mesh.height=.48; ear_mesh.radial_segments=5
		ear.mesh=ear_mesh; ear.position=Vector3(side*.27,1.48,-.015); ear.rotation.z=-side*.16; ear.material_override=mat(Color("#392642"),.7); player.add_child(ear)
		var ear_inner:=orb(player,Vector3(side*.27,1.49,-.12),.075,Color("#a65bba")); ear_inner.scale=Vector3(.65,1.6,.3)
		var w:=Node3D.new(); w.position=Vector3(side*.2,.42,.03); player.add_child(w); wings.append(w)
		var membrane:=MeshInstance3D.new(); membrane.mesh=make_bat_wing_mesh(side); membrane.position=Vector3(0,.18,0); membrane.rotation.z=side*.045; var membrane_material:=mat(Color("#493258"),.78); membrane_material.cull_mode=BaseMaterial3D.CULL_DISABLED; membrane.material_override=membrane_material; w.add_child(membrane)
		var rib_mat:=mat(Color("#82629a"),.65)
		for rib_i in range(3):
			var rib:=MeshInstance3D.new(); var rib_mesh:=BoxMesh.new(); rib_mesh.size=Vector3(.035,.67,.075); rib.mesh=rib_mesh
			rib.position=Vector3(side*(.42+rib_i*.32),.19, -.045); rib.rotation.z=side*(.15+rib_i*.16); rib.material_override=rib_mat; w.add_child(rib)
	# Small feet and a tapered tail tuft make the silhouette less spherical.
	for side in [-1.0,1.0]:
		var foot:=orb(player,Vector3(side*.2,-.28,-.03),.13,Color("#594064")); foot.scale=Vector3(.8,.65,1.25)
	var tail:=MeshInstance3D.new(); var tail_mesh:=CylinderMesh.new(); tail_mesh.top_radius=.025; tail_mesh.bottom_radius=.13; tail_mesh.height=.42; tail_mesh.radial_segments=5; tail.mesh=tail_mesh; tail.position=Vector3(0,-.08,.43); tail.rotation.x=PI*.35; tail.material_override=mat(Color("#493258")); player.add_child(tail); tail_visual=tail
	for p in [Vector3(-.17,1.04,-.39),Vector3(.17,1.04,-.39)]:
		var eye:=orb(player,p,.085,Color("#d5a6ff")); var em:=eye.material_override as StandardMaterial3D; em.emission_enabled=true; em.emission=Color("#b878ff"); em.emission_energy_multiplier=1.0
		var glint:=orb(player,p+Vector3(-.02,.025,-.055),.024,Color("#ffffff")); glint.scale=Vector3(1,1,.5)
func build_camera()->void:
	camera=Camera3D.new(); camera.position=Vector3(0,6.5,10.5); player.add_child(camera); camera.current=true; camera.look_at(Vector3(0,.7,0))
func make_hud_panel(parent:Control,pos:Vector2,size:Vector2,bg:Color,border:Color,radius:int)->Panel:
	var panel:=Panel.new()
	panel.position=pos
	panel.size=size
	var style:=StyleBoxFlat.new()
	style.bg_color=bg
	style.border_color=border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.shadow_color=Color(0,0,0,.42)
	style.shadow_size=8
	style.shadow_offset=Vector2(0,4)
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	return panel
func make_hud_label(parent:Control,pos:Vector2,size:Vector2,text_value:String,font_size:int,color:Color,alignment:=HORIZONTAL_ALIGNMENT_LEFT)->Label:
	var label:=Label.new()
	label.position=pos
	label.size=size
	label.text=text_value
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,.72))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",1)
	label.horizontal_alignment=alignment
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label
func build_hud()->void:
	var layer:=CanvasLayer.new()
	layer.layer=10
	add_child(layer)
	var root:=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	# Compact translucent status plate with separate color-coded counters.
	var status_panel:=make_hud_panel(root,Vector2(18,16),Vector2(490,142),Color(.025,.045,.105,.91),Color("#6654a9"),13)
	hud=make_hud_label(status_panel,Vector2(14,5),Vector2(230,29),"NIGHTBOUND",21,Color("#f3edff"))
	realm_label=make_hud_label(status_panel,Vector2(15,29),Vector2(425,20),"MOONLIT VALLEY • EXPLORATION",11,Color("#a8c9ed"))
	crystal_label=make_hud_label(status_panel,Vector2(15,51),Vector2(205,22),"◆ CRYSTALS 0/11",14,Color("#74e8ff"))
	seed_label=make_hud_label(status_panel,Vector2(247,51),Vector2(215,22),"✦ MOONSEEDS 0/5",14,Color("#e5a8ff"))
	shard_label=make_hud_label(status_panel,Vector2(15,75),Vector2(215,22),"✧ MOONSHARDS 0/3",13,Color("#f0aee2"))
	relic_label=make_hud_label(status_panel,Vector2(247,75),Vector2(215,22),"◇ RELICS 0/5",13,Color("#ffd78e"))
	make_hud_label(status_panel,Vector2(15,105),Vector2(88,18),"GLIDE ENERGY",9,Color("#a1b6db"))
	bar=ProgressBar.new()
	bar.position=Vector2(105,109)
	bar.size=Vector2(355,12)
	bar.max_value=GLIDE_MAX
	bar.show_percentage=false
	var bar_background:=StyleBoxFlat.new()
	bar_background.bg_color=Color("#151e3b")
	bar_background.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background",bar_background)
	var bar_fill:=StyleBoxFlat.new()
	bar_fill.bg_color=Color("#48d9d7")
	bar_fill.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill",bar_fill)
	status_panel.add_child(bar)
	# Round compass badge echoes the mockup's navigation dial without requiring image assets.
	var compass:=make_hud_panel(root,Vector2(1159,17),Vector2(101,101),Color(.025,.05,.12,.88),Color("#44cfe6"),50)
	make_hud_label(compass,Vector2(37,1),Vector2(27,20),"N",12,Color("#b8f5ff"),HORIZONTAL_ALIGNMENT_CENTER)
	make_hud_label(compass,Vector2(5,38),Vector2(20,22),"W",11,Color("#c2d4f5"),HORIZONTAL_ALIGNMENT_CENTER)
	make_hud_label(compass,Vector2(76,38),Vector2(20,22),"E",11,Color("#c2d4f5"),HORIZONTAL_ALIGNMENT_CENTER)
	make_hud_label(compass,Vector2(38,76),Vector2(25,20),"S",11,Color("#c2d4f5"),HORIZONTAL_ALIGNMENT_CENTER)
	compass_needle=make_hud_label(compass,Vector2(29,29),Vector2(42,42),"▲",23,Color("#78f0ef"),HORIZONTAL_ALIGNMENT_CENTER)
	gate_status_label=make_hud_label(root,Vector2(530,18),Vector2(220,32),"REALM GATE • LOCKED",12,Color("#d5c3ff"),HORIZONTAL_ALIGNMENT_CENTER)
	# Key legends are split into small groups so they remain readable at gameplay resolution.
	var ability_panel:=make_hud_panel(root,Vector2(900,611),Vector2(360,91),Color(.025,.045,.105,.88),Color("#554b92"),11)
	make_hud_label(ability_panel,Vector2(12,7),Vector2(158,29),"SPACE  GLIDE",12,Color("#b9f5ee"))
	make_hud_label(ability_panel,Vector2(183,7),Vector2(160,29),"E  ECHOSENSE",12,Color("#e2c1ff"))
	make_hud_label(ability_panel,Vector2(12,42),Vector2(158,29),"F  BURST",12,Color("#ffd9a1"))
	make_hud_label(ability_panel,Vector2(183,42),Vector2(165,29),"SHIFT  DASH",12,Color("#d1c4ff"))
	message=make_hud_label(root,Vector2(365,163),Vector2(550,32),"",15,Color("#ffe8b0"),HORIZONTAL_ALIGNMENT_CENTER)
	refresh_hud()
func refresh_hud()->void:
	if realm_label: realm_label.text=realm.to_upper()+" • EXPLORATION"
	if crystal_label: crystal_label.text="◆ CRYSTALS %d/11"%crystals
	if seed_label: seed_label.text="✦ MOONSEEDS %d/5"%moonseeds
	if shard_label: shard_label.text="✧ MOONSHARDS %d/3"%moonshards
	if relic_label: relic_label.text="◇ RELICS %d/5"%relics
	if gate_status_label:
		gate_status_label.text="REALM GATE • OPEN" if portal_open else "REALM GATE • LOCKED"
		gate_status_label.add_theme_color_override("font_color",Color("#80f3df") if portal_open else Color("#d5c3ff"))
	if bar: bar.value=GLIDE_MAX-glide

func _physics_process(d:float)->void:
	if not player:return
	if Input.is_action_just_pressed("save_game"):
		save_game(); show_message("Game saved — progress secured.")
	if Input.is_action_just_pressed("load_game"):
		if FileAccess.file_exists(SAVE_PATH): get_tree().reload_current_scene()
		else: show_message("No save file yet — press P to create one.")
	if Input.is_action_just_pressed("echosense"):
		echo_timer = 5.0
		for relic in relic_nodes:
			if is_instance_valid(relic):
				relic.visible = true
				var relic_material := relic.material_override as StandardMaterial3D
				if relic_material:
					relic_material.emission_enabled = true
					relic_material.emission = Color("#f8d58b")
					relic_material.emission_energy_multiplier = 1.8
		show_message("Echosense reveals hidden relics for 5 seconds.")
	var v:=Input.get_vector("move_left","move_right","move_forward","move_back"); var dir:=Vector3(v.x,0,v.y); if dir.length()>.05: player.rotation.y=atan2(-dir.x,-dir.z)
	if not player.is_on_floor():
		if Input.is_action_pressed("jump") and player.velocity.y<.5 and glide<GLIDE_MAX: glide=minf(glide+d,GLIDE_MAX); player.velocity.y=maxf(player.velocity.y-4*d,-2.4); player.velocity.x=move_toward(player.velocity.x,dir.x*9.4,18*d); player.velocity.z=move_toward(player.velocity.z,dir.z*9.4,18*d)
		else: player.velocity.x=dir.x*8; player.velocity.z=dir.z*8; player.velocity.y-=24*d
	else:
		glide=0; player.velocity.x=dir.x*8; player.velocity.z=dir.z*8; if Input.is_action_just_pressed("jump"): player.velocity.y=10.5
	if Input.is_action_just_pressed("burst"): player.velocity += -player.global_basis.z*13
	if Input.is_action_just_pressed("shadow_dash") and crystals>=8: player.velocity += -player.global_basis.z*18
	player.move_and_slide()
	for p in points:
		if player.global_position.distance_to(p)<2.1 and checkpoint_position.distance_to(p)>.2: checkpoint_position=p+Vector3(0,.8,0); save_game(); show_message("Checkpoint attuned — progress secured.")
	if player.global_position.y < -12: player.global_position=checkpoint_position; player.velocity=Vector3.ZERO; show_message("Back to the last safe checkpoint.")
	collect_near(crystal_nodes,1.25,"Crystal"); collect_near(shard_nodes,1.3,"Moonshard"); collect_near(seed_nodes,1.25,"Moonseed"); collect_near(relic_nodes,1.25,"Relic")
	if echo_timer > 0.0:
		echo_timer = maxf(0.0, echo_timer-d)
		if echo_timer == 0.0:
			for relic in relic_nodes:
				if is_instance_valid(relic) and not collected_relics.has(str(relic.name)):
					relic.visible = false
					var relic_material := relic.material_override as StandardMaterial3D
					if relic_material: relic_material.emission_enabled = false
	if crystals>=11 and not portal_open:
		portal_open=true
		set_gate_state(true)
		show_message("The Realm Gate awakens — the path is open!")
	if portal_open and realm=="Moonlit Valley" and player.global_position.distance_to(Vector3(0,2.5,-18))<3: realm="The Veilwood"; player.position=Vector3(130,2,4); checkpoint_position=Vector3(130,2,4); audio_director.call("play_track","veilwood_level_2"); save_game(); show_message("REALM SHIFT — Welcome to the Veilwood!")
	t+=d; body_visual.rotation.z=lerpf(body_visual.rotation.z,clampf(-player.velocity.x*.018,-.16,.16),d*4); body_visual.position.y=.25+sin(t*5.0)*.025; head_visual.rotation.z=lerpf(head_visual.rotation.z,clampf(player.velocity.x*.008,-.07,.07),d*5); head_visual.rotation.x=sin(t*3.2)*.025; tail_visual.rotation.z=sin(t*4.5)*.18; for wing_index in wings.size(): wings[wing_index].rotation.z=sin(t*8.5)*.3*(-1 if wing_index==0 else 1); for mote_index in mote_nodes.size(): mote_nodes[mote_index].position=mote_origins[mote_index]+Vector3(0,sin(t*1.3+float(mote_index)*.7)*.22,0); mote_nodes[mote_index].rotation.y=t*.25+float(mote_index); animate_collectibles(crystal_nodes); animate_collectibles(shard_nodes); animate_collectibles(seed_nodes); animate_collectibles(relic_nodes); if compass_needle: compass_needle.rotation=-player.rotation.y; refresh_hud()
func animate_collectibles(nodes:Array[MeshInstance3D])->void:
	for n in nodes:
		if not is_instance_valid(n): continue
		var origin:Vector3=n.get_meta("float_origin",n.position)
		var phase:float=float(n.get_meta("float_phase",0.0))
		n.position=origin+Vector3(0,sin(t*2.2+phase)*.13,0)
		n.rotation.y=sin(t*1.1+phase)*.18
		var material:=n.material_override as StandardMaterial3D
		if material and material.emission_enabled: material.emission_energy_multiplier=.8+.35*(.5+.5*sin(t*2.0+phase))
func collect_near(nodes:Array[MeshInstance3D],dist:float,label:String)->void:
	for i in range(nodes.size()-1,-1,-1):
		var n:=nodes[i]; if not is_instance_valid(n): nodes.remove_at(i); continue
		if label=="Relic" and not n.visible: continue
		if n.global_position.distance_to(player.global_position)<dist:
			var id:=str(n.name); n.queue_free(); nodes.remove_at(i)
			if label=="Crystal": crystals+=1; collected_crystals.append(id)
			elif label=="Moonshard": moonshards+=1; collected_shards.append(id)
			elif label=="Moonseed": moonseeds+=1; collected_seeds.append(id)
			else: relics+=1; collected_relics.append(id)
			show_message("%s collected!"%label); save_game()

func show_message(s:String)->void:
	if message: message.text=s
func save_game()->void:
	var f:=FileAccess.open(SAVE_PATH,FileAccess.WRITE); if f:f.store_string(JSON.stringify({"crystals":crystals,"moonseeds":moonseeds,"moonshards":moonshards,"relics":relics,"collected_relics":collected_relics,"collected_crystals":collected_crystals,"collected_shards":collected_shards,"collected_seeds":collected_seeds,"realm":realm,"checkpoint":[checkpoint_position.x,checkpoint_position.y,checkpoint_position.z]}))
func load_game()->void:
	if not FileAccess.file_exists(SAVE_PATH):return
	var f:=FileAccess.open(SAVE_PATH,FileAccess.READ); if not f:return
	var d=JSON.parse_string(f.get_as_text()); if typeof(d)!=TYPE_DICTIONARY:return
	crystals=int(d.get("crystals",0)); moonseeds=int(d.get("moonseeds",0)); moonshards=int(d.get("moonshards",0)); relics=int(d.get("relics",0)); collected_relics=d.get("collected_relics",[]); collected_crystals=d.get("collected_crystals",[]); collected_shards=d.get("collected_shards",[]); collected_seeds=d.get("collected_seeds",[]); realm=str(d.get("realm","Moonlit Valley")); portal_open=crystals>=11
	var cp=d.get("checkpoint",[0,1.5,3]); if cp is Array and cp.size()==3:checkpoint_position=Vector3(float(cp[0]),float(cp[1]),float(cp[2])); if player:player.position=checkpoint_position
	if audio_director:audio_director.call("play_track","veilwood_level_2" if realm=="The Veilwood" else "moonlit_valley_level_1"); refresh_hud()