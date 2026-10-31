# Nightbound Hero Bat V2 — Blender 4.x
# Refined first-pass generator based on the supplied Nightbound v1.0 mockup.
# V2.1 fixes a missing central wing-membrane triangle and adjusts preview framing.
# Run in Blender > Scripting > Run Script. Exports a GLB to the user's home folder.

import bpy, math, os
from mathutils import Vector

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def material(name, color, rough=.5, emission=None, strength=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value=(*color,1); p.inputs["Roughness"].default_value=rough
    if emission:
        p.inputs["Emission Color"].default_value=(*emission,1)
        p.inputs["Emission Strength"].default_value=strength
    return m

fur=material("Fur - midnight violet",(0.075,.035,.19),.72)
furhi=material("Fur - violet highlights",(.19,.09,.34),.68)
muzzle=material("Muzzle - plum",(.28,.12,.30),.6)
membrane=material("Wing membrane - magenta violet",(.31,.055,.42),.38)
rib=material("Wing fingers - dark violet",(.055,.025,.12),.48)
gold=material("Eyes - glowing gold",(1,.56,.055),.2,(1,.28,.015),.35)
pupil=material("Pupils",(.008,.004,.02),.18)
inner=material("Ear and wing accents",(.48,.10,.54),.4)

def ball(name, loc, scale, mat, seg=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, location=loc)
    o=bpy.context.object; o.name=name; o.scale=scale; o.data.materials.append(mat)
    bpy.ops.object.shade_smooth(); return o

def rod(name,a,b,r1,r2,mat,verts=10):
    a,b=Vector(a),Vector(b); d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r1,radius2=r2,depth=d.length,location=(a+b)/2)
    o=bpy.context.object; o.name=name; o.rotation_mode='QUATERNION'
    o.rotation_quaternion=d.to_track_quat('Z','Y'); o.data.materials.append(mat)
    bevel=o.modifiers.new("Soft edges","BEVEL"); bevel.width=.018; bevel.segments=2
    o.modifiers.new("Weighted normals","WEIGHTED_NORMAL"); return o

def tube(name, pts, radius, mat):
    c=bpy.data.curves.new(name,'CURVE'); c.dimensions='3D'; c.bevel_depth=radius; c.bevel_resolution=2
    s=c.splines.new('BEZIER'); s.bezier_points.add(len(pts)-1)
    for p,co in zip(s.bezier_points,pts):
        p.co=co; p.handle_left_type='AUTO'; p.handle_right_type='AUTO'
    o=bpy.data.objects.new(name,c); bpy.context.collection.objects.link(o); o.data.materials.append(mat)
    return o

# Face points toward -Y. Large head, tiny torso, tucked feet.
ball("Torso",(0,.02,.05),(.34,.30,.47),fur)
ball("Chest",(0,-.235,.12),(.22,.075,.27),furhi)
ball("Head",(0,-.13,.66),(.48,.39,.43),fur,20,14)
ball("Muzzle",(0,-.485,.49),(.19,.12,.14),muzzle)
ball("Nose",(0,-.59,.54),(.065,.035,.045),muzzle,12,8)

for side,tag in [(-1,"L"),(1,"R")]:
    rod("Pointed ear "+tag,(side*.28,-.07,.91),(side*.39,-.035,1.48),.17,.012,fur,12)
    ball("Inner ear "+tag,(side*.315,-.192,1.12),(.075,.035,.20),inner,12,8)
    ball("Eye socket "+tag,(side*.205,-.465,.70),(.135,.065,.15),rib)
    ball("Golden eye "+tag,(side*.205,-.519,.70),(.092,.045,.108),gold)
    ball("Pupil "+tag,(side*.205,-.558,.70),(.035,.018,.070),pupil,12,8)
    ball("Eye glint "+tag,(side*.177,-.577,.744),(.022,.012,.022),inner,8,6)
    ball("Thigh "+tag,(side*.20,.13,-.30),(.15,.17,.22),fur)
    rod("Shin "+tag,(side*.22,.13,-.39),(side*.28,-.01,-.59),.075,.055,fur,9)
    ball("Foot "+tag,(side*.29,-.10,-.61),(.12,.16,.075),furhi,12,8)
    for j in range(3):
        x=side*(.29+(j-1)*.055)
        rod("Toe "+tag+str(j),(x,-.18,-.62),(x+side*.015,-.27,-.66),.025,.006,rib,7)

# Three small swept tufts.
for i,(x,z,h) in enumerate([(-.15,1,.16),(0,1.08,.20),(.15,1,.15)]):
    rod("Crown tuft "+str(i),(x,.03,z),(x*1.15,.10,z+h),.09,.005,furhi,8)

# Wide bat wings, each built as a fan-shaped membrane with scalloped trailing edge.
def wing(side,tag):
    root=(side*.28,.05,.42); wrist=(side*.78,.04,.86); tip=(side*1.72,.08,1.22)
    edge=[(side*1.58,.08,.82),(side*1.42,.075,.47),(side*1.17,.07,.18),
          (side*.90,.065,.03),(side*.62,.06,.06)]
    verts=[root,wrist,tip]+edge
    faces=[(0,1,2)] + [(0,i,i+1) for i in range(2,len(verts)-1)]
    faces.append((0,len(verts)-1,1))
    me=bpy.data.meshes.new("Wing membrane mesh "+tag); me.from_pydata(verts,[],faces)
    me.materials.append(membrane)
    ob=bpy.data.objects.new("Wing membrane "+tag,me); bpy.context.collection.objects.link(ob)
    sol=ob.modifiers.new("Membrane thickness","SOLIDIFY"); sol.thickness=.018
    bev=ob.modifiers.new("Soft membrane edges","BEVEL"); bev.width=.012; bev.segments=2
    tube("Wing leading edge "+tag,[root,wrist,tip],.035,rib)
    targets=[tip]+edge
    for i,t in enumerate(targets):
        start=wrist if i==0 else root
        mid=((start[0]+t[0])*.52,.025,(start[2]+t[2])*.52+.05)
        tube("Wing finger "+tag+str(i),[start,mid,t],.025 if i==0 else .018,rib)
    tube("Wing inner seam "+tag,[root,(side*.55,.015,.39),(side*.82,.02,.22)],.012,inner)

wing(-1,"L"); wing(1,"R")
for i in range(4):
    z=.20-i*.12
    rod("Back tuft "+str(i),(0,.22,z),(0,.34,z-.12),.07,.004,furhi,8)

# Camera and lighting for a preview render.
bpy.ops.object.camera_add(location=(2.25,-6.8,2.0)); cam=bpy.context.object
target=Vector((0,0,.42)); cam.rotation_euler=(target-Vector(cam.location)).to_track_quat('-Z','Y').to_euler()
cam.data.lens=58; cam.data.type="ORTHO"; cam.data.ortho_scale=4.35; bpy.context.scene.camera=cam
bpy.ops.object.light_add(type='AREA',location=(0,-3,3.5)); key=bpy.context.object
key.data.energy=450; key.data.shape='DISK'; key.data.size=4
key.rotation_euler=(Vector((0,0,.4))-key.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.light_add(type='AREA',location=(2,2,1.8)); rim=bpy.context.object
rim.data.energy=280; rim.data.color=(.38,.18,1); rim.data.size=3
rim.rotation_euler=(Vector((0,0,.4))-rim.location).to_track_quat('-Z','Y').to_euler()

sc=bpy.context.scene; sc.render.engine='BLENDER_EEVEE_NEXT'
sc.render.resolution_x=1280; sc.render.resolution_y=720; sc.render.resolution_percentage=100
sc.render.image_settings.file_format='PNG'; sc.view_settings.view_transform='AgX'

# Export only character meshes/curves, excluding camera and lights.
bpy.ops.object.select_all(action='DESELECT')
for o in bpy.context.scene.objects:
    if o.type in {'MESH','CURVE'}: o.select_set(True)
bpy.context.view_layer.objects.active=next(o for o in bpy.context.scene.objects if o.type=='MESH')
out=os.environ.get("NIGHTBOUND_GLB",os.path.join(os.path.expanduser("~"),"Nightbound_Hero_Bat_V2_1.glb"))
bpy.ops.export_scene.gltf(filepath=out,export_format='GLB',use_selection=True)
print("Exported:",out)