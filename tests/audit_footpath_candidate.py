#!/usr/bin/env python3
"""Candidate exterior-waypoint/rounding only. Does not modify production files."""
import json,math,importlib.util
import numpy as np
from pathlib import Path
from scipy.spatial import cKDTree
import audit_footpath_geometry as a
ROOT=a.ROOT;OUT=a.OUT
OVERRIDES={f'{x},-1':[float(0),322.] for x in range(16)}
OVERRIDES.update({'-1,-1':[196.,326.],'16,-1':[730.,334.],'16,0':[750.,360.],'16,15':[739.,857.]})
def center(cell):
 x,y=cell;key=f'{int(x)},{int(y)}'
 if x==int(x) and y==int(y) and key in OVERRIDES:return np.array(OVERRIDES[key])
 # Original bilinear board projection (override applies only actual integer
 # exterior centers, never actual occupied board resources).
 p=a.L['board_plane'];tl,tr,bl,br=[np.array(p[k],float) for k in ['top_left','top_right','bottom_left','bottom_right']];fit=min(bl[1]-tl[1],557/16*15);tl[1]=bl[1]-fit;tr[1]=br[1]-fit;v=(y+.5)/15
 return (tl*(1-v)+bl*v)*(1-(x+.5)/16)+(tr*(1-v)+br*v)*((x+.5)/16)
def build(path,radius=12.):
 cells=[np.array(p,float) for p in path];route={'segments':[],'ends':[],'total_length':0.,'start_position':a.L['nest']['position'],'end_position':center(cells[-1]).tolist(),'start_depth':15.,'end_depth':float(cells[-1][1])}
 def append(pa,pb,pc,la,lb,lc,curve=False):
  ts=np.linspace(0,1,13)[:,None];points=(1-ts)**2*pa+2*(1-ts)*ts*pb+ts*ts*pc if curve else np.array([pa,pc]);ls=np.r_[0,np.cumsum(np.linalg.norm(np.diff(points,axis=0),axis=1))];length=ls[-1]
  if length<1e-6:return
  route['segments'].append({'a':pa.tolist(),'b':pb.tolist(),'c':pc.tolist(),'logical_a':la.tolist(),'logical_b':lb.tolist(),'logical_c':lc.tolist(),'curved':curve,'arc_lengths':ls.tolist(),'start':route['total_length'],'length':float(length)})
  route['total_length']+=length;route['ends'].append(float(route['total_length']))
 nest=np.array(a.L['nest']['position']);gate=np.array(a.L['nest']['gateway']);append(nest,nest,gate,cells[0],cells[0],cells[0]);append(gate,gate,center(cells[0]),cells[0],cells[0],cells[0]);prev=center(cells[0]);prevlogical=cells[0]
 for i,c in enumerate(cells[1:-1],1):
  inc=c-cells[i-1];out=cells[i+1]-c;interior=0<=c[0]<16 and 0<=c[1]<15;notnest=not(np.array_equal(cells[i-1],[8,15]) or np.array_equal(cells[i+1],[8,15]));oldround=interior and notnest and abs(inc@out)<1e-6 and abs(inc@inc-1)<1e-6 and abs(out@out-1)<1e-6
  if oldround:
   le=c-inc*.22;lx=c+out*.22;pe=center(le);px=center(lx);append(prev,prev,pe,prevlogical,prevlogical,le);append(pe,center(c),px,le,c,lx,True);prev=px;prevlogical=lx
  else:
   pc=center(c);p0=center(cells[i-1]);p2=center(cells[i+1]);v=pc-p0;w=p2-pc;lv=np.linalg.norm(v);lw=np.linalg.norm(w);bend=not interior and notnest and not np.array_equal(c,[8,15]) and lv>0 and lw>0 and (v@w)/(lv*lw)<.995
   if bend and radius:
    rad=min(radius,lv*.45,lw*.45);pe=pc-v/lv*rad;px=pc+w/lw*rad;le=c-inc*rad/lv;lx=c+out*rad/lw;append(prev,prev,pe,prevlogical,prevlogical,le);append(pe,pc,px,le,c,lx,True);prev=px;prevlogical=lx
   else:append(prev,prev,pc,prevlogical,prevlogical,c);prev=pc;prevlogical=c
 append(prev,prev,center(cells[-1]),prevlogical,prevlogical,cells[-1]);return route

def bounded(q,frame,phase,loaded,projected,moving=True):
 # Bounded weighted shader motion is inside convex hull of +/- stride. This
 # also covers the two inverse-warp steps, all phases, and corrected leg count.
 axis=np.array([math.cos(frame*math.pi/4),math.sin(frame*math.pi/4)*.42]);stride=(9 if loaded else 12)*moving
 shifts=[axis*stride,-axis*stride]
 if projected:shifts += [s+np.array([0,-(11 if loaded else 15)*moving]) for s in shifts]
 pts=np.concatenate([q+s for s in shifts]);pts=(pts-np.array(a.M['poses'][frame]['foot_anchor']))*62/420
 # Every toe pixel's displacement lies in this hull. Add .18 horizontal and
 # 0.16 loaded downward body support separately via the final 0.5px AA margin.
 pts=pts[__import__('scipy').spatial.ConvexHull(pts).vertices]
 return np.broadcast_to(pts,(len(phase),*pts.shape))
if __name__=='__main__':
 import argparse
 p=argparse.ArgumentParser();p.add_argument('--full',action='store_true');p.add_argument('--radius',type=float,default=12.);args=p.parse_args()
 a.M=json.loads((ROOT/'assets/first-level/slender-ants.json').read_text());a.L=json.loads((ROOT/'data/scenes/first-level-approved.json').read_text());a.D=json.loads((OUT/'audit_footpath_baseline_routes.json').read_text());a.H=np.array(a.L['walkable_polygon']);a.DIST=cKDTree(a.D['dragon_baked_points']);a.SHAPES,meta=a.shapes();a.deformed=bounded
 for x in range(16):OVERRIDES[f'{x},-1'][0]=a.D['plane_centers'][f'{x},-1'][0]
 orig=a.D['records'];sel=orig if args.full else [r for r in orig if 'initial' in r['sources']];records=[]
 for r in sel:records.append(dict(r,route=build(r['path'],args.radius)))
 result=a.audit(records,'candidate_bound');lengths=[n['route']['total_length']-o['route']['total_length'] for n,o in zip(records,sel)]
 report={'method':'Source alpha toe hull plus mathematically bounded planar stride +/-12 source pixels (loaded +/-9), every phase, at actual heading frames. No all-eight-yaw ellipse imposed on straight paths. Endpoint cells and board matrix, ant width, ball diameter, nest, gateway, dragon and Rules untouched. 0.5px AA margin; 60Hz sampled heading requires interpolation margin before acceptance.','exterior_centers':OVERRIDES,'exterior_corner_radius_px':args.radius,'result':result,'length_delta_px':{'minimum':min(lengths),'maximum':max(lengths),'all':lengths}}
 (OUT/'audit_footpath_candidate.json').write_text(json.dumps(report,indent=2));print(json.dumps({'worst':result['worst'],'length_delta':report['length_delta_px']|{'all':None}},indent=2))
