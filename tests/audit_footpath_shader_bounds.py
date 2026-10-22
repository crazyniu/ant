#!/usr/bin/env python3
import json,hashlib
import numpy as np
import audit_footpath_geometry as a
from pathlib import Path
from PIL import Image
a.M=json.loads((a.ROOT/'assets/first-level/slender-ants.json').read_text());shapes,meta=a.shapes();report={'method':'Current integrated 3-to-6 visible legs/groups. Every solid alpha toe ROI hull vertex, 720 equally spaced phase samples, outbound and returning. Exact two-step inverse warp solved numerically. Includes no carried ball or body in ground-contact sweep.','poses':[]}
atlas=np.array(Image.open(a.ROOT/'assets/first-level/slender-ants.png').convert('RGBA'))
for f,q in enumerate(shapes):
 data={'name':a.M['poses'][f]['name'],'visible_legs':len(a.M['poses'][f]['legs']),'groups':a.M['poses'][f]['leg_groups'],'ground_source_bounds':[q.min(0).tolist(),q.max(0).tolist()]}
 # Analytic bound for pickup posture, including every opaque ROI pixel, not
 # just hull vertices. Inner shader lookup is at most max posture away from q.
 pose=a.M['poses'][f];x,y,w,h=pose['region'];im=atlas[y:y+h,x:x+w];opaque=[]
 for xa,ya,xb,yb in pose['solid_toe_rois']:
  yy,xx=np.where(im[ya:yb,xa:xb,3]>=128);opaque.extend(np.c_[xx+xa,yy+ya].tolist())
 opaque=np.array(opaque,float);legs=np.array(pose['legs'],float);rad=.95/(62/420)+2**-.5;lower=[]
 for leg in legs:
  v=leg[2:]-leg[:2];vv=(v*v).sum();t=((opaque-leg[:2])*v).sum(-1)/vv;distance=np.linalg.norm(opaque-leg[:2]-np.clip(t,0,1)[:,None]*v,axis=1)+rad;along_min=np.clip(t-rad/np.sqrt(vv),0,1);lower.append((1-a.ss(18,38,distance))*a.ss(0,.72,along_min))
 body_upper=(1-a.ss(legs[:,1].min()-18,legs[:,3].max()-14,opaque[:,1]-rad))*(1-np.max(lower,axis=0));data['pickup_posture_upper_bound_px']=float(body_upper.max()*.95)
 axis=np.array([np.cos(f*np.pi/4),.42*np.sin(f*np.pi/4)]);data['analytic_gait_displacement_bound_px_excluding_posture']={}
 for loaded in [False,True]:
  stride=9 if loaded else 12;lift=11 if loaded else 15;mat=np.column_stack([axis*stride,[0,-lift]])
  data['analytic_gait_displacement_bound_px_excluding_posture']['returning' if loaded else 'outbound']={'planar_norm':float(np.linalg.norm(axis)*stride*62/420),'projected_norm':float(np.linalg.svd(mat,compute_uv=False)[0]*62/420)}
  phase=np.linspace(0,2*np.pi,721);name='returning' if loaded else 'outbound'
  for projected,label in [(False,'planar'),(True,'projected')]:
   d=a.deformed_exact(q,f,phase,loaded,projected);base=(q-np.array(a.M['poses'][f]['foot_anchor']))*62/420;delta=d-base
   pts=d/(62/420)+np.array(a.M['poses'][f]['foot_anchor']);mapped=pts-a.articulation(pts-a.articulation(pts,f,phase,loaded,projected),f,phase,loaded,projected)
   data[name+'_'+label]={'shift_min_px':delta.min((0,1)).tolist(),'shift_max_px':delta.max((0,1)).tolist(),'maximum_shift_norm_px':float(np.linalg.norm(delta,axis=-1).max()),'source_inverse_residual_px':float(np.linalg.norm(mapped-q,axis=-1).max())}
 report['poses'].append(data)
report['hashes']={p:hashlib.sha256((a.ROOT/p).read_bytes()).hexdigest() for p in ['assets/first-level/slender-ants.json','scripts/first_level_carrier.gdshader','scripts/first_level_carrier.gd']};(a.OUT/'audit_footpath_shader_bounds.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
