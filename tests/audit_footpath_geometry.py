#!/usr/bin/env python3
"""First-level geometry audit. Read-only production inputs; no GL or game saves.
Uses production-exported BFS routes, source-alpha foot-pad ROIs, and the actual
inverse-warp shader math. Contact sweep excludes upward swing lift; projected
foot pixels are separately reported. Neither is a whole-ant collision claim.
"""
import json, math, hashlib, argparse
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.spatial import ConvexHull,cKDTree
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'reports/first-level/batch-2'
# Manual image-pixel ROIs around EVERY visible distal toe, independently of old
# four-leg metadata. A few proximal pixels are deliberately retained. Source
# coordinates are local to each manifest region; alpha threshold is 128/255.
TOES={
'E':[(56,320,87,341),(253,348,282,370),(154,348,182,372),(306,313,340,335)],
'SE':[(19,219,52,239),(208,308,237,333),(102,275,131,302),(294,276,322,300)],
'S':[(17,224,49,247),(38,282,66,307),(82,324,112,352),(185,323,215,350),(222,281,249,307),(244,222,272,247)],
'SW':[(71,270,101,295),(149,310,179,338),(262,283,293,309),(333,233,363,260)],
'W':[(77,305,111,331),(157,349,187,378),(308,326,339,352),(191,263,221,291)],
'NW':[(73,252,102,279),(112,314,142,341),(202,348,231,377)],
'N':[(20,240,52,266),(36,310,65,337),(241,308,273,337),(247,222,278,247)],
'NE':[(149,356,179,383),(240,310,272,337),(291,264,323,290)]}

def ss(a,b,x):
 t=np.clip((x-a)/(b-a),0,1);return t*t*(3-2*t)
def articulation(p,frame,phase,loaded,projected=True,moving=True):
 # p [N,K,2], phase [N]. Exact shader articulation, including group overlap.
 legs=np.array(M['poses'][frame]['legs'],float); weights=[]
 for leg in legs:
  v=leg[2:]-leg[:2];along=np.clip(((p-leg[:2])*v).sum(-1)/max((v*v).sum(),1),0,1)
  dist=np.linalg.norm(p-leg[:2]-along[...,None]*v,axis=-1)
  weights.append((1-ss(18,38,dist))*ss(0,.72,along))
 weights=np.stack(weights,-1);groups=np.array(M['poses'][frame].get('leg_groups',[0,1,0,1] if frame in (2,6) else [0,0,1,1]))
 near=(weights*(1-groups)).max(-1);far=(weights*groups).max(-1);total=np.maximum(1,near+far)
 theta=frame*np.pi/4;axis=np.array([np.cos(theta),np.sin(theta)*.42]);stride=(9 if loaded else 12)*moving
 sin=np.sin(phase)[:,None];cos=np.cos(phase)[:,None];g1=axis[None,None,:]*sin[...,None]*stride;g2=-g1
 if projected:
  lift=(11 if loaded else 15)*moving;g1=g1.copy();g2=g2.copy();g1[...,1]-=np.maximum(0,cos)*lift;g2[...,1]-=np.maximum(0,-cos)*lift
 shift=(g1*near[...,None]+g2*far[...,None])/total[...,None]
 # Posture has no meaningful contribution at measured planted toe pads; retain
 # exact body mask and current sway/loaded offset, so that statement is tested.
 body=(1-ss(legs[:,1].min()-18,legs[:,3].max()-14,p[...,1]))*(1-weights.max(-1))
 posture=np.stack([np.sin(phase*2)*.18*moving,np.full(len(phase),.16*loaded)],-1)/(62/420)
 return shift+body[...,None]*posture[:,None,:]
def deformed_exact(q,frame,phase,loaded,projected,moving=True):
 p=np.broadcast_to(q,(len(phase),len(q),2)).copy()
 # Solve source = point-articulation(point-articulation(point)); the shader's
 # two inverse-warp steps, NOT merely q+articulation(q). 14 iterations sampled.
 for _ in range(14):p=q+articulation(p-articulation(p,frame,phase,loaded,projected,moving),frame,phase,loaded,projected,moving)
 # The fixed-point iteration may oscillate where two foot capsules overlap.
 # Refine only unresolved points with a bounded two-dimensional Newton solve.
 mapped=p-articulation(p-articulation(p,frame,phase,loaded,projected,moving),frame,phase,loaded,projected,moving)
 bad=np.linalg.norm(mapped-q,axis=-1)>1e-6
 if bad.any():
  phases=np.broadcast_to(phase[:,None],bad.shape)[bad];target=np.broadcast_to(q,p.shape)[bad][:,None,:];z=p[bad][:,None,:]
  def residual(z):return z-articulation(z-articulation(z,frame,phases,loaded,projected,moving),frame,phases,loaded,projected,moving)-target
  for _ in range(20):
   r=residual(z);eps=.0001;jx=(residual(z+np.array([eps,0]))-r)/eps;jy=(residual(z+np.array([0,eps]))-r)/eps;det=jx[...,0]*jy[...,1]-jy[...,0]*jx[...,1];det=np.where(abs(det)<1e-8,1e-8,det)
   step=np.stack([(jy[...,1]*r[...,0]-jy[...,0]*r[...,1])/det,(-jx[...,1]*r[...,0]+jx[...,0]*r[...,1])/det],-1);step*=np.minimum(1,5/np.maximum(1e-8,np.linalg.norm(step,axis=-1)))[...,None];z-=step
   if np.linalg.norm(residual(z),axis=-1).max()<1e-6:break
  p[bad]=z[:,0,:]
 return (p-np.array(M['poses'][frame]['foot_anchor']))*62/420

CACHE={}
def deformed(q,frame,phase,loaded,projected,moving=True):
 key=(frame,loaded,projected,moving)
 if key not in CACHE:
  CACHE[key]=deformed_exact(q,frame,np.linspace(0,2*np.pi,721),loaded,projected,moving)
 f=(phase%(2*np.pi))*720/(2*np.pi);i=np.floor(f).astype(int);w=(f-i)[:,None,None]
 return CACHE[key][i]*(1-w)+CACHE[key][i+1]*w

def shapes():
 im=np.array(Image.open(ROOT/'assets/first-level/slender-ants.png').convert('RGBA'));res=[];meta=[]
 for p in M['poses']:
  x,y,w,h=p['region'];imr=im[y:y+h,x:x+w];verts=[];boxes=[]
  for a,b,c,d in p.get('solid_toe_rois',TOES[p['name']]):
   yy,xx=np.where(imr[b:d,a:c,3]>=128);q=np.c_[xx+a,yy+b].astype(float);assert len(q)>0,(p['name'],a,b,c,d)
   hull=q[ConvexHull(q).vertices];verts.extend(hull);boxes.append({'roi':[a,b,c,d],'alpha_bounds':[q.min(0).tolist(),q.max(0).tolist()],'vertices':hull.tolist()})
  # Per-foot hulls are already compact; retain their union, not a single ellipse.
  res.append(np.array(verts));meta.append({'name':p['name'],'foot_count':len(boxes),'foot_regions':boxes,'source_scale':62/420,'foot_anchor':p['foot_anchor']})
 return res,meta

def clearance(points):
 points=np.asarray(points);shape=points.shape[:-1];p=points.reshape(-1,2);minimum=np.full(len(p),np.inf);inside=np.zeros(len(p),bool)
 for a,b in zip(H,np.roll(H,-1,axis=0)):
  v=b-a;t=np.clip(((p-a)*v).sum(1)/(v*v).sum(),0,1);minimum=np.minimum(minimum,np.linalg.norm(p-(a+t[:,None]*v),axis=1));inside^=((a[1]>p[:,1])!=(b[1]>p[:,1]))&(p[:,0]<(b[0]-a[0])*(p[:,1]-a[1])/(b[1]-a[1]+1e-30)+a[0])
 return np.where(inside,minimum,-minimum).reshape(shape)

def sample(route,frac):
 total=route['total_length'];distance=np.clip(frac,0,1)*total;ix=np.searchsorted(route['ends'],distance,side='left');ix=np.minimum(ix,len(route['segments'])-1)
 pos=np.zeros((len(frac),2));tan=pos.copy();dep=np.zeros(len(frac))
 for i,s in enumerate(route['segments']):
  which=ix==i
  if not which.any():continue
  d=np.clip(distance[which]-s['start'],0,s['length']);t=d/s['length']
  if s['curved']:t=np.interp(d,s['arc_lengths'],np.linspace(0,1,13))
  a,b,c=[np.array(s[k]) for k in ['a','b','c']];u=t[:,None]
  pos[which]=(1-u)**2*a+2*(1-u)*u*b+u*u*c if s['curved'] else a+(c-a)*u
  tan[which]=(b-a)*(1-u)+(c-b)*u if s['curved'] else c-a
  la,lb,lc=[np.array(s[k]) for k in ['logical_a','logical_b','logical_c']]
  dep[which]=((1-t)**2*la[1]+2*(1-t)*t*lb[1]+t*t*lc[1]) if s['curved'] else la[1]+(lc[1]-la[1])*t
 pos[frac<=0]=route['start_position'];pos[frac>=1]=route['end_position'];return pos,tan,.88+.12*np.clip(dep/15,0,1)

def headings(tangents,dt,initial=None):
 target=np.arctan2(tangents[:,1],tangents[:,0]);heading=target[0] if initial is None else initial;prior=int(np.floor(heading/(np.pi/4)+.5))%8;out=[]
 for tar in target:
  diff=(tar-heading+np.pi)%(2*np.pi)-np.pi;heading+=(np.clip(diff,-np.pi/.4*dt,np.pi/.4*dt));f=int(np.floor(heading/(np.pi/4)+.5))%8
  if abs((heading-prior*np.pi/4+np.pi)%(2*np.pi)-np.pi)<np.pi/8+np.pi/72:f=prior
  prior=f;out.append(f)
 return np.array(out),heading

def audit(records,name,sample_hz=60):
 worst={'ground':{'clearance':1e9},'projected':{'clearance':1e9},'dragon':{'clearance':1e9}};route_results=[];sample_count=0;cloud_count=0;targets=set()
 for ri,r in enumerate(records):
  route=r['route'];total=route['total_length'];distance=r['distance_cells']+8.25;targets.add(tuple(r['path'][-1]));mins={k:1e9 for k in worst}; stages=[]
  for loaded in [False,True]:
   duration=distance/(2 if loaded else 2.5);n=math.ceil(duration*sample_hz)+1;dt=duration/(n-1);frac=np.linspace(1,0,n) if loaded else np.linspace(0,1,n);pos,tangent,depth=sample(route,frac)
   if loaded:tangent=-tangent
   frames,last=headings(tangent,dt);travel=frac*total;phase=2*np.pi*((total if loaded else travel)/(33.5*2.5/3.6)+(total-travel if loaded else 0)/(33.5*2/3.1))+1.7
   stages.append((pos,depth,frames,phase,loaded,True,frac))
   if not loaded:
    # During the real 0.30 s pickup hold the rendered yaw turns by +180 degrees.
    u=np.linspace(0,1,37);ang=last+np.pi*ss(0,1,u);frameshold=[];prior=frames[-1]
    for a in ang:
     f=int(np.floor(a/(np.pi/4)+.5))%8
     if abs((a-prior*np.pi/4+np.pi)%(2*np.pi)-np.pi)<np.pi/8+np.pi/72:f=prior
     frameshold.append(f);prior=f
    stages.append((np.repeat(pos[-1:],len(u),0),np.repeat(depth[-1],len(u)),np.array(frameshold),np.full(len(u),phase[-1]),False,False,np.ones(len(u))))
  for pos,depth,frames,phase,loaded,moving,frac in stages:
   sample_count+=len(pos)
   for f in np.unique(frames):
    idx=np.where(frames==f)[0];q=SHAPES[f]
    # Running only one source phase is explicitly an actual-distance reference
    # audit, not all possible spawn phase offsets or arbitrary frame schedules.
    for projected,key in [(False,'ground'),(True,'projected')]:
     local=deformed(q,f,phase[idx],loaded,projected,moving);points=pos[idx,None,:]+local*depth[idx,None,None];cloud_count+=len(points)*points.shape[1]
     cl=clearance(points)-.5;flat=int(cl.argmin());j,k=np.unravel_index(flat,cl.shape);value=float(cl[j,k]);mins[key]=min(mins[key],value)
     if value<worst[key]['clearance']:
      worst[key]={'clearance':value,'target':r['path'][-1],'path':r['path'],'source_labels':r['sources'],'stage':'returning' if loaded else ('outbound' if moving else 'pickup'),'frame':M['poses'][f]['name'],'position':pos[idx[j]].tolist(),'foot_pixel':points[j,k].tolist(),'phase':float(phase[idx[j]]),'fraction':float(frac[idx[j]])}
     if not projected:
      ds=DIST.query(points.reshape(-1,2),workers=1)[0].reshape(points.shape[:-1]);flat=int(ds.argmin());j,k=np.unravel_index(flat,ds.shape);value=float(ds[j,k])-.5;mins['dragon']=min(mins['dragon'],value)
      if value<worst['dragon']['clearance']:worst['dragon']={'clearance':value,'target':r['path'][-1],'stage':'returning' if loaded else ('outbound' if moving else 'pickup'),'frame':M['poses'][f]['name'],'position':pos[idx[j]].tolist(),'foot_pixel':points[j,k].tolist()}
  route_results.append({'target':r['path'][-1],'sources':r['sources'],'length':total,**mins})
  if ri%50==0:print(name,ri,'/',len(records),worst['ground']['clearance'],flush=True)
 return {'name':name,'routes':len(records),'covered_resource_targets':len(targets),'time_pose_samples':sample_count,'foot_vertex_samples':cloud_count,'worst':worst,'route_results':route_results}

if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--limit',type=int,default=0);parser.add_argument('--candidate',default='');args=parser.parse_args()
 M=json.loads((ROOT/'assets/first-level/slender-ants.json').read_text());L=json.loads((ROOT/'data/scenes/first-level-approved.json').read_text());D=json.loads((OUT/'audit_footpath_production_routes.json').read_text());H=np.array(L['walkable_polygon']);DIST=cKDTree(np.array(D['dragon_baked_points']));SHAPES,meta=shapes()
 records=D['records'];records=records[:args.limit] if args.limit else records
 report={'method':'Production BFS/CarrierRoute export; measured source-alpha visible-toe ROI hulls; two-step inverse-warp solved by 14 fixed-point iterations plus bounded Newton refinement; 60 Hz simulation-time travel plus 37 pickup-turn samples; actual-distance phase with task-id=1; separate planar-contact and lifted screen projection; 0.5 logical px AA pad. All 240 resources appear in production BFS routes on 8 progressively cleared geometry fixtures, plus initial and actual authored replay. Does not prove every possible board topology or frame schedule. No GL or human acceptance.','poses':meta,'current':audit(records,'current'),'hashes':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in ['assets/first-level/slender-ants.png','assets/first-level/slender-ants.json','scripts/first_level_carrier.gd','scripts/first_level_carrier.gdshader','scripts/carrier_route.gd','data/scenes/first-level-approved.json','data/serpent-levels/serpent-01.json']}}
 (OUT/'audit_footpath_geometry.json').write_text(json.dumps(report,indent=2));print(json.dumps(report['current']['worst'],indent=2))
