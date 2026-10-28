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
var glide := 0.0
var checkpoint := Vector3(0,1.5,3)
var points: Array[Vector3] = []
var crystal_nodes: Array[MeshInstance3D] = []
var shard_nodes: Array[MeshInstance3D] = []
var seed_nodes: Array[MeshInstance3D] = []
var collected_crystals: Array[String] = []
var collected_shards: Array[String] = []
var collected_seeds: Array[String] = []
var portal_open := false
var t := 0.0
var body_visual: MeshInstance3D
var head_visual: MeshInstance3D
var wings: Array[Node3D] = []

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
	var n:=MeshInstance3D.new(); var mesh:=CylinderMesh.new(); mesh.top_radius=.03; mesh.bottom_radius=.32; mesh.height=1.4; mesh.radial_segments=6; n.mesh=mesh; n.position=pos; var m:=mat(c,.2); m.emission_enabled=true; m.emission=c; m.emission_energy_multiplier=1.0; n.material_override=m; add_child(n); return n
func cliff(p:Vector3,s:float)->void:
	for i in range(4):
		var n:=orb(self,p+Vector3(cos(i*1.57)*s*.45,(i%2)*s*.25,sin(i*1.57)*s*.45),s*(.75+(i%2)*.12),Color("#4d5872") if i%2==0 else Color("#66718a")); n.scale=Vector3(1,1.25,0.8)
func checkpoint(p:Vector3)->void:
	points.append(p); var r:=MeshInstance3D.new(); var tm:=TorusMesh.new(); tm.inner_radius=.5; tm.outer_radius=.68; r.mesh=tm; r.position=p+Vector3(0,.08,0); r.rotation.x=PI*.5; var m:=mat(Color("#83f4df"),.2); m.emission_enabled=true; m.emission=Color("#50e7dd"); m.emission_energy_multiplier=1.5; r.material_override=m; add_child(r)
func tree(p:Vector3,scale_value:=1.0,forest_color:=Color("#304a3b"))->void:
	var trunk:=MeshInstance3D.new(); var tm:=CylinderMesh.new(); tm.top_radius=.18*scale_value; tm.bottom_radius=.32*scale_value; tm.height=2.8*scale_value; tm.radial_segments=7; trunk.mesh=tm; trunk.position=p+Vector3(0,1.4*scale_value,0); trunk.material_override=mat(Color("#44374a"),.95); add_child(trunk)
	var crown:=MeshInstance3D.new(); var cm:=SphereMesh.new(); cm.radius=1.45*scale_value; cm.height=2.3*scale_value; cm.radial_segments=9; cm.rings=5; crown.mesh=cm; crown.position=p+Vector3(0,3.0*scale_value,0); crown.scale=Vector3(1,.9,.82); crown.material_override=mat(forest_color,.9); add_child(crown)
	var glow:=orb(self,p+Vector3(0,3.55*scale_value,0),.12*scale_value,Color("#83e6bd")); var gm:=glow.material_override as StandardMaterial3D; gm.emission_enabled=true; gm.emission=Color("#67dcae"); gm.emission_energy_multiplier=.8
func build_valley()->void:
	var w:=WorldEnvironment.new(); var e:=Environment.new(); e.background_mode=Environment.BG_COLOR; e.background_color=Color("#10182d"); e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color=Color("#8195cf"); e.ambient_light_energy=.58; e.fog_enabled=true; e.fog_density=.008; w.environment=e; add_child(w)
	var light:=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-48,-32,0); light.light_color=Color("#b8ccff"); light.light_energy=1.15; light.shadow_enabled=true; add_child(light)
	box(Vector3(0,-.5,0),Vector3(100,1,100),Color("#416b43"),true)
	for p in [Vector3(-12,.4,-9),Vector3(11,1.2,-14),Vector3(17,.4,9),Vector3(-17,3.2,13),Vector3(-30,1,-20),Vector3(-38,2.4,-28),Vector3(-27,3.8,-36),Vector3(28,1,-22),Vector3(38,2.5,-32),Vector3(31,4,-40),Vector3(-31,1,24),Vector3(-39,2.6,34),Vector3(-27,4,40),Vector3(29,1,25),Vector3(39,2.8,35),Vector3(27,4.2,42)]: box(p,Vector3(8,1.2,8),Color("#668b58"),true)
	for p in [Vector3(-43,1.4,-17),Vector3(43,1.6,-20),Vector3(-41,2.4,28),Vector3(41,2.7,29),Vector3(-15,2,-39),Vector3(16,2.2,-41)]: cliff(p,3.3)
	for p in [Vector3(-21,0,-4),Vector3(18,0,-7),Vector3(-33,0,8),Vector3(34,0,8),Vector3(-12,0,31),Vector3(15,0,34),Vector3(-40,0,-7),Vector3(41,0,-8)]: tree(p,1.15,Color("#31533f"))
	for p in [Vector3(-8,0,10),Vector3(8,0,14),Vector3(-22,0,16),Vector3(22,0,18)]: tree(p,.72,Color("#3e6247"))
	box(Vector3(0,.1,7),Vector3(2.5,.4,9),Color("#9b7047"),true)
	for i in range(72):
		var p:=Vector3(float(((i*17)%83)-41),.03,float(((i*29)%87)-43)); var g:=box(p+Vector3(0,.3,0),Vector3(.06,.6,.18),Color("#6d9b62") if i%3==0 else Color("#47785a")); g.rotation.y=float(i%3)*2.09; g.rotation.z=.12
	var ps=[Vector3(-5,1,-5),Vector3(7,1.5,-12),Vector3(-14,1.2,-10),Vector3(-25,1.5,-21),Vector3(-38,3.2,-29),Vector3(25,1.5,-23),Vector3(38,3.4,-33),Vector3(-25,1.5,24),Vector3(-38,3.5,35),Vector3(25,1.6,25),Vector3(38,3.7,36)]
	for i in range(11):
		var id:="crystal_%02d"%i; if not collected_crystals.has(id): var n:=gem(ps[i],Color("#68e9ff")); n.name=id; crystal_nodes.append(n)
	var bonus_positions: Array[Vector3]=[Vector3(-31,3,-27),Vector3(32,3.2,-29),Vector3(-27,5,-36)]
	for i in range(3):
		var id:="moonshard_%02d"%i; if not collected_shards.has(id): var n:=gem(bonus_positions[i],Color("#f4baff")); n.name=id; shard_nodes.append(n)
	checkpoint(Vector3(0,1.5,3)); checkpoint(Vector3(-25,1.5,-21)); checkpoint(Vector3(25,1.5,-23))
	box(Vector3(-2.25,2.4,-18),Vector3(.75,4.8,1),Color("#45445f"),true); box(Vector3(2.25,2.4,-18),Vector3(.75,4.8,1),Color("#45445f"),true); box(Vector3(0,4.85,-18),Vector3(5.1,.75,1),Color("#56516e"),true)
func build_veilwood()->void:
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
	player=CharacterBody3D.new(); player.name="NightboundBat"; player.position=checkpoint; add_child(player); var cs:=CollisionShape3D.new(); var cap:=CapsuleShape3D.new(); cap.radius=.42; cap.height=1.45; cs.shape=cap; player.add_child(cs)
	body_visual=orb(player,Vector3(0,.25,0),.55,Color("#2e243b")); body_visual.scale=Vector3(.78,1.15,.75); head_visual=orb(player,Vector3(0,.95,-.02),.48,Color("#3b2b47")); head_visual.scale=Vector3(.9,.95,.9)
	for side in [-1.0,1.0]:
		orb(player,Vector3(side*.28,1.3,-.02),.28,Color("#493258")); var w:=Node3D.new(); player.add_child(w); wings.append(w); var mem:=box(Vector3(side*.75,.2,0),Vector3(1.45,.7,.06),Color("#493258")); mem.rotation.z=side*.35; w.add_child(mem)
	for p in [Vector3(-.17,1.04,-.39),Vector3(.17,1.04,-.39)]: var eye:=orb(player,p,.085,Color("#d5a6ff")); var em:=eye.material_override as StandardMaterial3D; em.emission_enabled=true; em.emission=Color("#b878ff"); em.emission_energy_multiplier=1.0
func build_camera()->void:
	camera=Camera3D.new(); camera.position=Vector3(0,6.5,10.5); player.add_child(camera); camera.current=true; camera.look_at(Vector3(0,.7,0))
func build_hud()->void:
	var layer:=CanvasLayer.new(); add_child(layer); hud=Label.new(); hud.position=Vector2(22,18); hud.add_theme_font_size_override("font_size",20); layer.add_child(hud); message=Label.new(); message.position=Vector2(22,100); message.size=Vector2(1000,48); layer.add_child(message); bar=ProgressBar.new(); bar.position=Vector2(22,145); bar.size=Vector2(220,16); bar.max_value=GLIDE_MAX; layer.add_child(bar); refresh_hud()
func _physics_process(d:float)->void:
	if not player:return
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
		if player.global_position.distance_to(p)<2.1 and checkpoint.distance_to(p)>.2: checkpoint=p+Vector3(0,.8,0); save_game(); show_message("Checkpoint attuned — progress secured.")
	if player.global_position.y < -12: player.global_position=checkpoint; player.velocity=Vector3.ZERO; show_message("Back to the last safe checkpoint.")
	collect_near(crystal_nodes,1.25,"Crystal"); collect_near(shard_nodes,1.3,"Moonshard"); collect_near(seed_nodes,1.25,"Moonseed")
	if crystals>=11: portal_open=true
	if portal_open and realm=="Moonlit Valley" and player.global_position.distance_to(Vector3(0,2.5,-18))<3: realm="The Veilwood"; player.position=Vector3(130,2,4); checkpoint=Vector3(130,2,4); audio_director.call("play_track","veilwood_level_2"); save_game(); show_message("REALM SHIFT — Welcome to the Veilwood!")
	t+=d; body_visual.rotation.z=lerpf(body_visual.rotation.z,clampf(-player.velocity.x*.018,-.16,.16),d*4); head_visual.rotation.z=lerpf(head_visual.rotation.z,clampf(player.velocity.x*.008,-.07,.07),d*5); for i in wings.size(): wings[i].rotation.z=sin(t*8.5)*.3*(-1 if i==0 else 1); refresh_hud()
func collect_near(nodes:Array[MeshInstance3D],dist:float,label:String)->void:
	for i in range(nodes.size()-1,-1,-1):
		var n:=nodes[i]; if not is_instance_valid(n): nodes.remove_at(i); continue
		if n.global_position.distance_to(player.global_position)<dist:
			var id:=str(n.name); n.queue_free(); nodes.remove_at(i)
			if label=="Crystal": crystals+=1; collected_crystals.append(id)
			elif label=="Moonshard": moonshards+=1; collected_shards.append(id)
			else: moonseeds+=1; collected_seeds.append(id)
			show_message("%s collected!"%label); save_game()
func refresh_hud()->void:
	if hud: hud.text="NIGHTBOUND  •  %s\nCrystals: %d/11  •  Moonseeds: %d/5  •  Moonshards: %d/3%s\nWASD Move | SPACE Leap/Glide | F Burst | SHIFT Dash | P Save | O Load"%[realm,crystals,moonseeds,moonshards,"  •  GATE OPEN" if portal_open else ""]
	if bar: bar.value=GLIDE_MAX-glide
func show_message(s:String)->void:
	if message: message.text=s
func save_game()->void:
	var f:=FileAccess.open(SAVE_PATH,FileAccess.WRITE); if f:f.store_string(JSON.stringify({"crystals":crystals,"moonseeds":moonseeds,"moonshards":moonshards,"collected_crystals":collected_crystals,"collected_shards":collected_shards,"collected_seeds":collected_seeds,"realm":realm,"checkpoint":[checkpoint.x,checkpoint.y,checkpoint.z]}))
func load_game()->void:
	if not FileAccess.file_exists(SAVE_PATH):return
	var f:=FileAccess.open(SAVE_PATH,FileAccess.READ); if not f:return
	var d=JSON.parse_string(f.get_as_text()); if typeof(d)!=TYPE_DICTIONARY:return
	crystals=int(d.get("crystals",0)); moonseeds=int(d.get("moonseeds",0)); moonshards=int(d.get("moonshards",0)); collected_crystals=d.get("collected_crystals",[]); collected_shards=d.get("collected_shards",[]); collected_seeds=d.get("collected_seeds",[]); realm=str(d.get("realm","Moonlit Valley")); portal_open=crystals>=11
	var cp=d.get("checkpoint",[0,1.5,3]); if cp is Array and cp.size()==3:checkpoint=Vector3(float(cp[0]),float(cp[1]),float(cp[2])); if player:player.position=checkpoint
	if audio_director:audio_director.call("play_track","veilwood_level_2" if realm=="The Veilwood" else "moonlit_valley_level_1"); refresh_hud()