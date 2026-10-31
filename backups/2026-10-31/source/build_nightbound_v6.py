"""Nightbound Hero Bat V6 — original mockup-referenced gliding character.
Generates a GLB containing independently animated wing pivots and a two-view PNG.
Requires numpy, trimesh, pillow, matplotlib. No Blender or Godot needed.
This is authored game-ready candidate geometry, not verified in Godot.
"""
from pathlib import Path
import numpy as np, trimesh, math, json, struct, io, zipfile
from PIL import Image, ImageDraw, ImageFont

OUT=Path('/mnt/data')
COLORS={
 'fur':(35,25,91,255), 'fur_light':(70,54,143,255), 'back':(55,39,127,255),
 'cheek':(69,39,119,255), 'muzzle':(116,69,139,255), 'ears':(178,82,189,255),
 'membrane':(143,56,168,255), 'membrane_light':(198,101,207,255),
 'membrane_shadow':(101,38,139,255), 'wing_edges':(43,25,98,255),
 'ribs':(63,29,106,255), 'edge_glow':(163,91,220,255),
 'gold':(245,185,73,255), 'eye':(252,231,139,255), 'pupil':(13,12,36,255),
 'nose':(88,44,111,255), 'claw':(99,91,142,255), 'spark':(228,203,255,255)
}
hero=[]
wing_parts={-1:[],1:[]}
def color_mesh(m,mat):
 m.visual.vertex_colors=np.tile(np.array(COLORS[mat],dtype=np.uint8),(len(m.vertices),1))
 return m

def put(name,mesh,material,side=0):
 color_mesh(mesh,material)
 if side: wing_parts[side].append((name,mesh))
 else: hero.append((name,mesh))
 return mesh

def ellipsoid(name,p,scale,mat,sub=2,side=0):
 m=trimesh.creation.icosphere(subdivisions=sub)
 m.apply_scale(scale);m.apply_translation(p)
 return put(name,m,mat,side)

def cylinder(name,a,b,r,mat,side=0,sections=9):
 a=np.asarray(a,float);b=np.asarray(b,float);d=b-a
 if np.linalg.norm(d)<1e-5: return None
 m=trimesh.creation.cylinder(radius=r,height=np.linalg.norm(d),sections=sections)
 m.apply_transform(trimesh.geometry.align_vectors([0,0,1],d))
 m.apply_translation((a+b)/2)
 return put(name,m,mat,side)

def cone(name,a,b,r,mat,side=0,sections=9):
 a=np.asarray(a,float);b=np.asarray(b,float);d=b-a
 m=trimesh.creation.cone(radius=r,height=np.linalg.norm(d),sections=sections)
 m.apply_transform(trimesh.geometry.align_vectors([0,0,1],d));m.apply_translation(a)
 return put(name,m,mat,side)

def polyline(name,pts,r,mat,side=0):
 for i,(a,b) in enumerate(zip(pts[:-1],pts[1:])):
  cylinder(f'{name} {i:02}',a,b,r,mat,side)

def fin(name,pts,mat,side=0):
 # a double-sided sheet. Counter- and clockwise triangles intentionally provided.
 v=np.asarray(pts,float)
 faces=[[0,i,i+1] for i in range(1,len(v)-1)]
 faces += [[c,b,a] for a,b,c in faces[:]]
 m=trimesh.Trimesh(vertices=v,faces=np.asarray(faces),process=False)
 return put(name,m,mat,side)

# Coordinate convention: +Y is travel direction. The mockup sees the BACK of
# the bat, viewed from negative Y, not a standing front-facing pose.
# The head is slightly ahead of the torso, the hips and feet trail backward.
ellipsoid('Head rounded violet',(0,.27,.56),(.43,.34,.43),'fur',3)
ellipsoid('Torso streamlined',(0,-.14,.04),(.31,.43,.29),'fur',3)
ellipsoid('Shoulder ridge',(0,-.14,.29),(.33,.20,.17),'fur_light')
ellipsoid('Back colored saddle',(0,-.40,.10),(.235,.12,.21),'back')
ellipsoid('Chest forward',(0,.16,.04),(.22,.20,.25),'muzzle')
ellipsoid('Muzzle forward',(0,.58,.42),(.16,.12,.12),'muzzle')
ellipsoid('Little nose',(0,.695,.48),(.048,.036,.035),'nose')

for s,label in [(-1,'L'),(1,'R')]:
 # Large expressive high ears with lavender inner lining, visible in rear view.
 cone('Ear '+label,(s*.25,.29,.84),(s*.38,.29,1.40),.17,'fur')
 ellipsoid('Ear inset '+label,(s*.295,.44,1.06),(.077,.030,.165),'ears')
 # Main frontal eyes: preserved for when the character turns to the camera.
 ellipsoid('Socket '+label,(s*.19,.535,.65),(.125,.068,.14),'wing_edges')
 ellipsoid('Golden eye '+label,(s*.19,.591,.65),(.10,.040,.105),'gold')
 ellipsoid('Pupil '+label,(s*.19,.623,.64),(.045,.017,.065),'pupil')
 ellipsoid('Eye glint '+label,(s*.16,.639,.69),(.018,.012,.020),'eye',1)
 # Rear view prominent cheek tufts.
 ellipsoid('Cheek '+label,(s*.34,.23,.44),(.12,.12,.12),'fur_light')
 cone('Cheek tuft '+label,(s*.37,.22,.46),(s*.52,.11,.50),.075,'fur')
 # Backward streaming legs, closely matching the flying mockup.
 ellipsoid('Hip '+label,(s*.16,-.40,-.11),(.145,.18,.15),'fur')
 cylinder('Thigh '+label,(s*.16,-.44,-.12),(s*.24,-.63,-.23),.105,'fur')
 cylinder('Shin '+label,(s*.24,-.63,-.23),(s*.33,-.86,-.30),.072,'fur')
 ellipsoid('Foot '+label,(s*.33,-.88,-.31),(.105,.145,.073),'fur_light')
 for j in range(3):
  x=s*(.33+(j-1)*.045)
  cone('Trailing toe '+label+str(j),(x,-.94,-.33),(x+s*.02,-1.06,-.37),.025,'claw')

# White-violet hair tuft located on the upper back in the main mockup.
for i,(x,z,w) in enumerate([(-.16,.31,.12),(-.065,.34,.18),(.05,.35,.18),(.145,.31,.11)]):
 cone('Nape tuft '+str(i),(x,-.37,z),(x*1.25,-.52,z+w),.073,'fur_light')
for i,(x,z) in enumerate([(-.12,.98),(0,1.045),(.12,.98)]):
 cone('Crown tuft '+str(i),(x,.22,z),(x*1.1,.16,z+.14),.058,'fur_light')

# Wings are mesh groups in their OWN parent pivot nodes. Meshes use local
# shoulder space, so Godot and the glTF animation can rotate them separately.
def create_wing(s,label):
 # Shoulder at (s*.33,-.12,.31) in hero scene space.
 # Measurements below are local offsets. Wingspan / body width intentionally
 # broad in the same spirit as the mockup's prominent gliding silhouette.
 def P(x,y,z): return (s*x,y,z)
 root=P(0,0,0)
 elbow=P(.39,.025,.33)
 wrist=P(.82,.08,.48)
 tip=P(2.36,.04,.61)
 # Scalloped trailing edge defined by fingertip dips and intermediate notches.
 edge=[
 P(2.19,-.08,.44),P(2.06,-.14,.42),
 P(1.88,-.27,.20),P(1.71,-.20,.27),
 P(1.52,-.40,.00),P(1.36,-.31,.095),
 P(1.18,-.45,-.16),P(1.01,-.34,-.075),
 P(.85,-.43,-.23),P(.66,-.30,-.14),
 P(.40,-.33,-.22),P(.20,-.19,-.15)
 ]
 # Shade polygons in bands to create a membrane with geometry-defined folds.
 lead=[root,elbow,wrist,tip]
 fin(f'{label} shoulder leading membrane',lead,'membrane_shadow',s)
 fin(f'{label} entire scalloped membrane',[root,wrist,tip]+edge,'membrane',s)
 # Local segmented accent panels use triangles inside the wing contour.
 highlights=[
 [wrist,P(1.64,-.07,.42),P(1.52,-.31,.065)],
 [root,wrist,P(1.18,-.37,-.13),P(.85,-.36,-.19)],
 [wrist,P(2.10,-.065,.435),P(1.80,-.24,.22)]
 ]
 for i,poly in enumerate(highlights):
  fin(f'{label} violet inner membrane {i}',poly,'membrane_light' if i==0 else 'membrane_shadow',s)
 polyline(label+' leading rib',[root,elbow,wrist,tip],.026,'wing_edges',s)
 # Natural radial fingers to the scallop tips.
 fingertips=[tip,edge[2],edge[4],edge[6],edge[8],edge[10]]
 for i,dest in enumerate(fingertips):
  anchor=wrist if i<3 else root
  midpoint=tuple((np.asarray(anchor)+np.asarray(dest))/2+np.array([0,-.045,.055]))
  polyline(f'{label} membrane finger {i}',[anchor,midpoint,dest],.013 if i>0 else .021,'ribs',s)
 # Fine bright border only on outermost top edge, moonlit rim.
 polyline(label+' purple edge glint',[P(.90,.074,.51),P(1.49,.052,.575),tip],.010,'edge_glow',s)
 cone(label+' wingtip talon',tip,P(2.44,-.04,.57),.020,'claw',s)
 cone(label+' thumb',wrist,P(.90,-.07,.53),.018,'claw',s)

create_wing(-1,'Left')
create_wing(1,'Right')

scene=trimesh.Scene()
parts=[]
for name,m in hero:
 scene.add_geometry(m,geom_name='Hero '+name,node_name='Body_'+name.replace(' ','_'))
 parts.append(name)
# Concatenate colored components into a single object per wing pivot; this is a
# practical named animation target, not a claimed armature/skinned skeleton.
for s,label in [(-1,'Left'),(1,'Right')]:
 wing_mesh=trimesh.util.concatenate([m for n,m in wing_parts[s]])
 mat=np.eye(4);mat[:3,3]=[s*.33,-.12,.31]
 scene.add_geometry(wing_mesh,geom_name='Wing_'+label,node_name='Wing_'+label+'_Pivot',transform=mat)

GLB_PATH=OUT/'Nightbound_Hero_Bat_V6_Animated.glb'
GLB_PATH.write_bytes(scene.export(file_type='glb'))

# Patch glTF's JSON+binary chunks with valid animation samplers/channels.
def read_glb(bs):
 magic,version,total=struct.unpack_from('<III',bs,0)
 assert magic==0x46546C67 and version==2 and total==len(bs)
 off=12; chunks=[]
 while off<len(bs):
  length,kind=struct.unpack_from('<II',bs,off);off+=8
  chunks.append((kind,bs[off:off+length]));off+=length
 return chunks

def pack_glb(js,blob):
 j=json.dumps(js,separators=(',',':'),ensure_ascii=False).encode('utf-8')
 j+=b' ' * ((-len(j))%4)
 b=blob+b'\x00'*((-len(blob))%4)
 return struct.pack('<III',0x46546C67,2,12+8+len(j)+8+len(b))+struct.pack('<II',len(j),0x4E4F534A)+j+struct.pack('<II',len(b),0x004E4942)+b

bs=GLB_PATH.read_bytes();chunks=read_glb(bs)
js=json.loads(next(b for kind,b in chunks if kind==0x4E4F534A))
blob=bytearray(next(b for kind,b in chunks if kind==0x004E4942))
nodeids={node.get('name'):i for i,node in enumerate(js['nodes'])}
assert 'Wing_Left_Pivot' in nodeids and 'Wing_Right_Pivot' in nodeids, list(nodeids)

def accessor(data,dtype,atype):
 arr=np.asarray(data,dtype=dtype)
 while len(blob)%4:blob.append(0)
 start=len(blob);blob.extend(arr.tobytes())
 bv=len(js.setdefault('bufferViews',[]))
 js['bufferViews'].append({'buffer':0,'byteOffset':start,'byteLength':arr.nbytes})
 count=len(arr) if arr.ndim>1 else arr.size
 ac={'bufferView':bv,'componentType':5126,'count':int(count),'type':atype}
 if atype=='SCALAR':ac['min']=[float(np.min(arr))];ac['max']=[float(np.max(arr))]
 acc=len(js.setdefault('accessors',[]));js['accessors'].append(ac)
 return acc

def qy(angle):return [0,math.sin(angle/2),0,math.cos(angle/2)]

def clip(name,times,left,right):
 anim={'name':name,'samplers':[],'channels':[]}
 ti=accessor(times,'<f4','SCALAR')
 for label,ang in [('Left',left),('Right',right)]:
  qi=accessor([qy(a) for a in ang],'<f4','VEC4')
  ix=len(anim['samplers'])
  anim['samplers'].append({'input':ti,'output':qi,'interpolation':'LINEAR'})
  anim['channels'].append({'sampler':ix,'target':{'node':nodeids['Wing_'+label+'_Pivot'],'path':'rotation'}})
 js.setdefault('animations',[]).append(anim)

# Matched signs yield both wings upward/inward depending on the side.
# Neutral glide is the opening pose of the mesh.
clip('Glide',[0,.5,1,1.5,2],[-.025,-.055,0,.04,-.025],[.025,.055,0,-.04,.025])
clip('Flap',[0,.24,.48,.72,.96,1.2],[0,.36,-.05,-.33,-.12,0],[0,-.36,.05,.33,.12,0])
clip('Bank_Left',[0,.5,1,1.5,2],[-.05,-.24,-.28,-.1,-.05],[.05,-.015,.02,.015,.05])
clip('Bank_Right',[0,.5,1,1.5,2],[-.05,-.015,-.02,-.015,-.05],[.05,.24,.28,.1,.05])
# glTF/Godot use Y as vertical and -Z as character forward. The authoring
# geometry is Z-up and +Y forward; rotate the whole asset -90 degrees on X.
# Keep wing pivot animations in their unchanged LOCAL coordinate space.
old_roots=list(js['scenes'][js.get('scene',0)]['nodes'])
root_idx=len(js['nodes'])
js['nodes'].append({'name':'Nightbound_Root_Y_Up',
                    'rotation':[-math.sqrt(.5),0,0,math.sqrt(.5)],
                    'children':old_roots})
js['scenes'][js.get('scene',0)]['nodes']=[root_idx]
js['buffers'][0]['byteLength']=len(blob)
GLB_PATH.write_bytes(pack_glb(js,blob))

# Structural verification: both geometry parsing and glTF animation graph.
loaded=trimesh.load(GLB_PATH,force='scene')
checkchunks=read_glb(GLB_PATH.read_bytes())
check=json.loads(next(b for k,b in checkchunks if k==0x4E4F534A))
assert len(check['animations'])==4
assert all(len(a['channels'])==2 for a in check['animations'])
assert 'Wing_Left_Pivot' in [n.get('name') for n in check['nodes']]
assert check['scenes'][check.get('scene',0)]['nodes']==[len(check['nodes'])-1]
assert check['nodes'][-1]['name']=='Nightbound_Root_Y_Up'
assert len(loaded.geometry)>=2
assert len(GLB_PATH.read_bytes())>=check['buffers'][0]['byteLength']

# Render directly from exported mesh data (not illustration/AI image), two angles.
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

def mesh_objects():
 # geometric meshes including pivot transforms, colors after GLB roundtrip
 result=[]
 for n in scene.graph.nodes_geometry:
  transform,g=scene.graph[n]
  mesh=scene.geometry[g].copy();mesh.apply_transform(transform)
  result.append((n,mesh))
 return result

def render_view(azim,label):
 fig=plt.figure(figsize=(8,7.8),facecolor='#091329')
 ax=fig.add_subplot(111,projection='3d',facecolor='#091329')
 for n,mesh in mesh_objects():
  tris=mesh.triangles
  count=len(tris)
  if count>7500:tris=tris[::max(1,count//7500)]
  colors=np.asarray(mesh.visual.vertex_colors[:,:3],dtype=float)/255
  facecols=colors[mesh.faces][:,0,:]
  if len(facecols)>len(tris):facecols=facecols[::max(1,count//7500)][:len(tris)]
  # Studio lighting: retain vertex colors; add gentle fill for dark purple fur.
  facecols=np.clip(facecols*.95 + np.array([.09,.10,.15]),0,1)
  alpha=.87 if 'Wing_' in n else 1
  rgba=np.column_stack((facecols,np.full(len(facecols),alpha)))
  ax.add_collection3d(Poly3DCollection(tris,facecolors=rgba,edgecolors='none',zsort='average'))
 ax.set_xlim(-2.90,2.90)
 ax.set_ylim(-1.35,1.15)
 ax.set_zlim(-.70,1.55)
 ax.set_box_aspect((5.8,2.5,2.25))
 ax.view_init(elev=13,azim=azim)
 ax.set_axis_off()
 fig.subplots_adjust(left=0,right=1,bottom=.04,top=.91)
 fig.text(.5,.93,label,color='#f2e6ff',ha='center',fontsize=19,weight='bold')
 bio=io.BytesIO()
 plt.savefig(bio,format='png',dpi=140,facecolor=fig.get_facecolor())
 plt.close(fig);bio.seek(0)
 return Image.open(bio).convert('RGB')

rear=render_view(-90,'VISTA POSTERIORE  /  PLANATA')
front=render_view(90,'VISTA FRONTALE  /  VOLTO')
w=rear.width;h=rear.height
panel=Image.new('RGB',(w*2,h+90),(6,14,31));panel.paste(rear,(0,90));panel.paste(front,(w,90))
d=ImageDraw.Draw(panel)
fontpath='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
f=ImageFont.truetype(fontpath,37) if Path(fontpath).exists() else ImageFont.load_default()
d.text((42,20),'NIGHTBOUND   /   HERO BAT V6',fill=(242,226,255),font=f)
panel.save(OUT/'Nightbound_Hero_Bat_V6_preview.png',optimize=True)

report={
 'asset':'Nightbound Hero Bat V6 — animated wing pivots',
 'reference':'Uploaded Nightbound v1.0 mockup; main scene flying purple bat, rear view',
 'geometry_parts_source':len(hero)+sum(len(v) for v in wing_parts.values()),
 'meshes_in_export':len(loaded.geometry),
 'wing_nodes':['Wing_Left_Pivot','Wing_Right_Pivot'],
 'animations':[{ 'name':a['name'],'channel_count':len(a['channels'])} for a in check['animations']],
 'authored_bounds_z_up':np.asarray(scene.bounds).round(3).tolist(),
 'expected_bounds_y_up':np.asarray([[scene.bounds[0,0], scene.bounds[0,2],-scene.bounds[1,1]], [scene.bounds[1,0],scene.bounds[1,2],-scene.bounds[0,1]]]).round(3).tolist(),
 'coordinate_system':'glTF Y-up; forward -Z; root conversion from Z-up authoring',
 'glb_bytes':GLB_PATH.stat().st_size,
 'tests':['Y-up root conversion applied','glTF 2.0 parsed','trimesh loaded','animation samplers/channels present','two mesh-based preview views rendered'],
 'not_tested':['Godot 4 import','Godot AnimationPlayer playback','gameplay animations','collision and optimization'],
 'notes':'Wings are separately pivot-animated rigid meshes, not skinned/deformable wing membranes. First fidelity pass, not a literal 1:1 sculpt of the mockup.'
}
(OUT/'Nightbound_Hero_Bat_V6_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
README='''# NIGHTBOUND — Hero Bat V6 (31 October 2026)\n\nThis package is a *first* 3D recreation of the purple flying hero in the supplied Nightbound v1.0 mockup, not a final photorealistic likeness. The build script authors with +Z up / +Y forward; the exported GLB converts this to **Godot Y-up / -Z forward** through a parent node.\n\n## Files\n- `Nightbound_Hero_Bat_V6_Animated.glb`: GLB 2.0 with separately pivoting wings and four animation clips: Glide, Flap, Bank_Left, Bank_Right.\n- `Nightbound_Hero_Bat_V6_preview.png`: mesh-based orthographic visualization from rear and front, not an image-generation mockup.\n- `build_nightbound_v6.py`: reproducible script (Python, numpy, trimesh, PIL, matplotlib).\n- `Nightbound_Hero_Bat_V6_report.json`: structural verification and limitations.\n\n## Godot 4 integration (NOT yet tested)\n1. Drag GLB into the project `res://assets/models/hero/`. Godot should import a glTF scene.\n2. Open imported scene; inspect wing pivot nodes `Wing_Left_Pivot` and `Wing_Right_Pivot`.\n3. Check whether glTF imported animation clips `Glide`, `Flap`, `Bank_Left`, `Bank_Right` are available through AnimationPlayer. Play them to check hinge direction.\n4. Scale gameplay collider separately and attach a kinematic/character controller in a wrapper scene; GLB does not contain a collision shape.\n5. The GLB should be Y-up and -Z forward already. Verify the forward direction and scale in a test scene before connecting gameplay controls.\n\n## Known limitations\n- No armature, skin weights or deformation inside membranes; wing root animations rotate rigid wings.\n- No Godot engine validation, performance test or game scene integration.\n- Stylized geometric proxy, not exact textures, fur grooming or facial animation.\n- Exported geometry can be heavier than needed for mobile/web; measure draw calls after import.\n'''
(OUT/'Nightbound_Hero_Bat_V6_README.md').write_text(README,encoding='utf-8')
with zipfile.ZipFile(OUT/'NIGHTBOUND_HERO_BAT_V6_PACK.zip','w',compression=zipfile.ZIP_DEFLATED) as z:
 for fname in ['Nightbound_Hero_Bat_V6_Animated.glb','Nightbound_Hero_Bat_V6_preview.png','build_nightbound_v6.py','Nightbound_Hero_Bat_V6_report.json','Nightbound_Hero_Bat_V6_README.md']:
  z.write(OUT/fname,arcname=fname)
print(json.dumps(report,indent=2))
print('ZIP',(OUT/'NIGHTBOUND_HERO_BAT_V6_PACK.zip').stat().st_size)