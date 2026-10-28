extends Node3D

const SAVE_PATH := "user://nightbound_save.json"
const GLIDE_MAX := 2.8
const AudioDirectorScript = preload("res://scripts/audio_director.gd")
var player: CharacterBody3D
var camera: Camera3D
var hud: Label
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

func mat(c:Color, r:=0.8)->StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=c; m.roughness=r; return m
func box(pos:Vector3,size:Vector3,c:Color,solid:=false)->MeshInstance3D:
	var n:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size; n.mesh=mesh; n.position=pos; n.material_override=mat(c); add_child(n)
	if solid:
		var b:=StaticBody3D.new(); b.position=pos; var cs:=CollisionShape3D.new(); var sh:=BoxShape3D.new(); sh.size=size; cs.shape=sh; b.add_child(cs); add_child(b); n.reparent(b)
	return n
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
	var crown:=MeshInstance3D.new(); var cm:=SphereMesh.new(); cm.radius=1.45*scale_value; cm.height=2.3*scale_value; cm.radial_segments=9; cm.rings=5; crown.mesh=cm; crown.position=p+Vector3(0,3.0*scale_value,0); crown.scale=Vector3(1,.9,.82); crown.material_override=mat(forest_color,.9); add_child(crown)
	var glow:=orb(self,p+Vector3(0,3.55*scale_value,0),.12*scale_value,Color("#83e6bd")); var gm:=glow.material_override as StandardMaterial3D; gm.emission_enabled=true; gm.emission=Color("#67dcae"); gm.emission_energy_multiplier=.8
func grass_cluster(p:Vector3,scale_value:float,add_bloom:bool)->void:
	# Three individually angled low-poly blades make small readable vegetation clumps.
	var blade_colors:Array[Color]=[Color("#47745f"),Color("#5f8d6e"),Color("#709678")]
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
func build_valley_ground_detail()->void:
	# Keep a clear central traversal corridor while adding foreground and side-plane texture.
	var rock_colors:Array[Color]=[Color("#435968"),Color("#536979"),Color("#384d5e"),Color("#617582")]
	for i in range(24):
		var x_pos:=float(((i*29)%79)-39)
		if absf(x_pos)<11.0:
			x_pos=signf(x_pos)*12.0
		var z_pos:=float(((i*37)%83)-41)
		var size:=Vector3(.65+float(i%4)*.16,.22+float(i%3)*.09,.52+float((i*3)%4)*.13)
		rock(Vector3(x_pos,.08,z_pos),size,rock_colors[i%rock_colors.size()],i+83)
	for i in range(60):
		var x_pos:=float(((i*23)%87)-43)
		var z_pos:=float(((i*31)%87)-43)
		# Preserve clear landing space around the entry bridge and the primary route.
		if absf(x_pos)<9.0 and z_pos>-23.0 and z_pos<14.0:
			continue
		if absf(x_pos)<5.0 and absf(z_pos+18.0)<8.0:
			continue
		grass_cluster(Vector3(x_pos,.015,z_pos),.68+float(i%4)*.13,i%6==0)
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
	box(Vector3(0,-.5,0),Vector3(100,1,100),Color("#2f4d49"),true)
	var platform_positions:Array[Vector3]=[Vector3(-12,.4,-9),Vector3(11,1.2,-14),Vector3(17,.4,9),Vector3(-17,3.2,13),Vector3(-30,1,-20),Vector3(-38,2.4,-28),Vector3(-27,3.8,-36),Vector3(28,1,-22),Vector3(38,2.5,-32),Vector3(31,4,-40),Vector3(-31,1,24),Vector3(-39,2.6,34),Vector3(-27,4,40),Vector3(29,1,25),Vector3(39,2.8,35),Vector3(27,4.2,42)]
	for platform_index in range(platform_positions.size()):
		plateau(platform_positions[platform_index],Vector3(8,1.2,8),platform_index)
	for p in [Vector3(-43,1.4,-17),Vector3(43,1.6,-20),Vector3(-41,2.4,28),Vector3(41,2.7,29),Vector3(-15,2,-39),Vector3(16,2.2,-41)]: cliff(p,3.3)
	for p in [Vector3(-21,0,-4),Vector3(18,0,-7),Vector3(-33,0,8),Vector3(34,0,8),Vector3(-12,0,31),Vector3(15,0,34),Vector3(-40,0,-7),Vector3(41,0,-8)]: tree(p,1.15,Color("#31533f"))
	for p in [Vector3(-8,0,10),Vector3(8,0,14),Vector3(-22,0,16),Vector3(22,0,18)]: tree(p,.72,Color("#3e6247"))
	build_entry_bridge()
	build_valley_ground_detail()
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
		var membrane:=box(Vector3(side*.76,.18,0),Vector3(1.5,.78,.055),Color("#493258")); membrane.rotation.z=side*.31; w.add_child(membrane)
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
func build_hud()->void:
	var layer:=CanvasLayer.new(); add_child(layer); hud=Label.new(); hud.position=Vector2(22,18); hud.add_theme_font_size_override("font_size",20); layer.add_child(hud); message=Label.new(); message.position=Vector2(22,100); message.size=Vector2(1000,48); layer.add_child(message); bar=ProgressBar.new(); bar.position=Vector2(22,145); bar.size=Vector2(220,16); bar.max_value=GLIDE_MAX; layer.add_child(bar); refresh_hud()
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
	if crystals>=11: portal_open=true
	if portal_open and realm=="Moonlit Valley" and player.global_position.distance_to(Vector3(0,2.5,-18))<3: realm="The Veilwood"; player.position=Vector3(130,2,4); checkpoint_position=Vector3(130,2,4); audio_director.call("play_track","veilwood_level_2"); save_game(); show_message("REALM SHIFT — Welcome to the Veilwood!")
	t+=d; body_visual.rotation.z=lerpf(body_visual.rotation.z,clampf(-player.velocity.x*.018,-.16,.16),d*4); body_visual.position.y=.25+sin(t*5.0)*.025; head_visual.rotation.z=lerpf(head_visual.rotation.z,clampf(player.velocity.x*.008,-.07,.07),d*5); head_visual.rotation.x=sin(t*3.2)*.025; tail_visual.rotation.z=sin(t*4.5)*.18; for wing_index in wings.size(): wings[wing_index].rotation.z=sin(t*8.5)*.3*(-1 if wing_index==0 else 1); for mote_index in mote_nodes.size(): mote_nodes[mote_index].position=mote_origins[mote_index]+Vector3(0,sin(t*1.3+float(mote_index)*.7)*.22,0); mote_nodes[mote_index].rotation.y=t*.25+float(mote_index); animate_collectibles(crystal_nodes); animate_collectibles(shard_nodes); animate_collectibles(seed_nodes); animate_collectibles(relic_nodes); refresh_hud()
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
func refresh_hud()->void:
	if hud: hud.text="NIGHTBOUND  •  %s\nCrystals: %d/11  •  Moonseeds: %d/5  •  Moonshards: %d/3  •  Relics: %d/5%s\nWASD Move | SPACE Leap/Glide | E Echosense | F Burst | SHIFT Dash | P Save | O Load"%[realm,crystals,moonseeds,moonshards,relics,"  •  GATE OPEN" if portal_open else ""]
	if bar: bar.value=GLIDE_MAX-glide
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