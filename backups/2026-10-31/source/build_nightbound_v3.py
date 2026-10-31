import numpy as np, trimesh, math, json
from pathlib import Path
from PIL import Image, ImageDraw
O=Path('/mnt/data'); scene=trimesh.Scene(); items=[]
colors={'fur':(32,20,79,255),'highlight':(75,49,137,255),'muzzle':(94,52,112,255),'wing':(133,44,160,255),'winglight':(180,79,194,255),'ribs':(38,18,86,255),'eyes':(255,182,39,255),'pupil':(10,7,26,255),'glint':(255,245,207,255)}
def add(name,mesh,color):
 mesh.visual.vertex_colors=np.tile(np.array(colors[color],dtype=np.uint8),(len(mesh.vertices),1));scene.add_geometry(mesh,geom_name=name);items.append((name,mesh,color))
def ball(name,p,scale,color,sub=2):
 m=trimesh.creation.icosphere(subdivisions=sub);m.apply_scale(scale);m.apply_translation(p);add(name,m,color)
def rod(name,a,b,r,color,sections=8):
 a=np.array(a);b=np.array(b);d=b-a
 m=trimesh.creation.cylinder(radius=r,height=np.linalg.norm(d),sections=sections)
 T=trimesh.geometry.align_vectors([0,0,1],d);m.apply_transform(T);m.apply_translation((a+b)/2);add(name,m,color)
def cone(name,a,b,r,color):
 a=np.array(a);b=np.array(b);d=b-a;m=trimesh.creation.cone(radius=r,height=np.linalg.norm(d),sections=9)
 m.apply_transform(trimesh.geometry.align_vectors([0,0,1],d));m.apply_translation(a);add(name,m,color)
def membrane(name,side):
 # shoulder -> elevated wrist -> pointed tip -> scalloped trailing edge
 coords=[(.27,.04,.38),(.72,.01,.72),(1.67,.04,1.13),(1.55,.045,.83),(1.37,.045,.47),(1.12,.04,.20),(.87,.04,.08),(.59,.035,.08)]
 v=np.array([[side*x,y,z] for x,y,z in coords],float)
 faces=[[0,1,2]]+[[0,i,i+1] for i in range(2,len(v)-1)]+[[0,len(v)-1,1]]
 # double sided triangles for reliable GLB visualization
 f=np.array(faces+[[a,c,b] for a,b,c in faces],int)
 m=trimesh.Trimesh(vertices=v,faces=f,process=False);add(name,m,'wing')
 rod(name+' leading shoulder',v[0],v[1],.043,'ribs')
 rod(name+' leading tip',v[1],v[2],.030,'ribs')
 for i in range(3,8):
  start=v[1] if i<5 else v[0]; rod(name+' finger '+str(i),start,v[i],.016,'ribs')
 # midmembrane colored accent as a smaller inset polygon
 inner=np.array([[side*x,y-.009,z] for x,y,z in [(.73,.012,.66),(1.40,.012,.81),(1.27,.012,.51),(.94,.012,.25)]])
 m=trimesh.Trimesh(vertices=inner,faces=[[0,1,2],[0,2,3],[2,1,0],[3,2,0]],process=False);add(name+' inner accent',m,'winglight')
ball('compact torso',(0,.04,.05),(.31,.26,.41),'fur')
ball('nape and head',(0,-.08,.61),(.43,.36,.39),'fur',3)
ball('belly bib',(0,-.205,.10),(.20,.07,.25),'highlight')
ball('short muzzle',(0,-.412,.45),(.16,.11,.12),'muzzle')
ball('nose',(0,-.516,.51),(.05,.035,.035),'highlight')
for side,t in [(-1,'left'),(1,'right')]:
 cone(t+' pointed ear',(side*.25,-.06,.85),(side*.34,-.025,1.41),.14,'fur')
 ball(t+' inner ear',(side*.285,-.176,1.06),(.075,.025,.17),'winglight')
 ball(t+' eye socket',(side*.18,-.389,.66),(.115,.05,.13),'ribs')
 ball(t+' golden eye',(side*.18,-.434,.66),(.082,.035,.10),'eyes')
 ball(t+' pupil',(side*.18,-.464,.66),(.035,.015,.066),'pupil')
 ball(t+' glint',(side*.156,-.482,.706),(.018,.009,.02),'glint')
 ball(t+' thigh',(side*.17,.14,-.28),(.13,.15,.18),'fur')
 rod(t+' bent shin',(side*.19,.13,-.35),(side*.27,-.04,-.53),.055,'fur')
 ball(t+' foot',(side*.28,-.09,-.54),(.10,.13,.06),'highlight')
 for i in range(3):
  x=side*(.28+(i-1)*.046);rod(t+' toe '+str(i),(x,-.17,-.54),(x,-.24,-.57),.012,'ribs')
 membrane(t+' wing',side)
for i,(x,z) in enumerate([(-.13,.99),(0,1.06),(.13,.99)]):cone('crown tuft '+str(i),(x,.08,z),(x*1.2,.17,z+.13),.065,'highlight')
for i in range(3):cone('nape tuft '+str(i),(0,.20,.40-i*.13),(0,.31,.31-i*.13),.052,'highlight')
# GLB and verification
path=O/'Nightbound_Hero_Bat_V3.glb';path.write_bytes(scene.export(file_type='glb'))
loaded=trimesh.load(path,force='scene');assert len(loaded.geometry)>30
report={'reference':'User supplied Nightbound_v1_0_preview.png','model':'Hero Bat V3','file':path.name,'geometry_parts':len(loaded.geometry),'bounds_m':np.asarray(loaded.bounds).round(3).tolist(),'status':'GLB generated and parsed successfully with trimesh; not imported into Godot; no rig or animation'}
(O/'Nightbound_Hero_Bat_V3_report.json').write_text(json.dumps(report,indent=2))
# Simple orthographic front view, color-coded actual mesh triangles, no artistic invented rendering.
import matplotlib;matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
fig=plt.figure(figsize=(10,6),facecolor='#080d24');ax=fig.add_subplot(111,projection='3d',facecolor='#080d24')
for name,mesh,c in items:
 rgba=np.array(colors[c])/255
 # translucent for membrane, opaque elsewhere
 alpha=.80 if c in ('wing','winglight') else 1
 tris=mesh.triangles
 if len(tris)>1200:tris=tris[::max(1,len(tris)//1200)]
 ax.add_collection3d(Poly3DCollection(tris,facecolors=[(*rgba[:3],alpha)],edgecolors='none',zsort='average'))
ax.set_xlim(-1.85,1.85);ax.set_ylim(.8,-1.0);ax.set_zlim(-.8,1.55)
ax.set_box_aspect((3.7,1.8,2.35));ax.view_init(elev=10,azim=-90)
ax.set_axis_off();fig.text(.5,.94,'NIGHTBOUND  /  HERO BAT V3',ha='center',color='white',fontsize=19,weight='bold')
fig.text(.5,.075,'Mesh preview • mockup-inspired blockout • GLB verified',ha='center',color='#b9b0e9',fontsize=10)
plt.savefig(O/'Nightbound_Hero_Bat_V3_preview.png',dpi=155,facecolor=fig.get_facecolor(),bbox_inches='tight');plt.close(fig)
print(json.dumps(report,indent=2));print('preview', (O/'Nightbound_Hero_Bat_V3_preview.png').stat().st_size)