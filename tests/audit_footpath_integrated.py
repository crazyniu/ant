#!/usr/bin/env python3
"""Verify REAL Godot-exported updated routes, not the Python proposal builder."""
import json,hashlib,math,sys
import numpy as np
from scipy.spatial import cKDTree
import audit_footpath_geometry as a
import audit_footpath_candidate as c
ROOT=a.ROOT;OUT=a.OUT
a.M=json.loads((ROOT/'assets/first-level/slender-ants.json').read_text());a.L=json.loads((ROOT/'data/scenes/first-level-approved.json').read_text());a.D=json.loads((OUT/'audit_footpath_production_routes.json').read_text());old=json.loads((OUT/'audit_footpath_baseline_routes.json').read_text());assert len(a.D['records'])==369
a.H=np.array(a.L['walkable_polygon']);a.DIST=cKDTree(a.D['dragon_baked_points']);a.SHAPES,meta=a.shapes();a.deformed=c.bounded
for path,sha in a.D['hashes'].items():assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==sha,('Stale production route export',path)
if '--reuse-measurement' in sys.argv:
 prior=json.loads((OUT/'audit_footpath_integrated.json').read_text())
 for path,sha in prior['hashes'].items():assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==sha,('Stale bound measurement',path)
 result=prior['result']
else:result=a.audit(a.D['records'],'integrated_production_bound',120)
assert a.M==json.loads((ROOT/'assets/first-level/slender-ants.json').read_text()),'Manifest changed during measurement'
for path,sha in a.D['hashes'].items():assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==sha,('Production changed during measurement',path)
oldmap={json.dumps(r['path']):r for r in old['records']};lengths=[];delta=[];errors=[];old_speed=[];new_speed=[];fixed=[]
for r in a.D['records']:
 prev=oldmap[json.dumps(r['path'])];lengths.append(r['route']['total_length']);delta.append(r['route']['total_length']-prev['route']['total_length']);p,t,d=a.sample(r['route'],np.linspace(0,1,101));q=np.array([v['position'] for v in r['production_probes']]);errors.append(float(np.linalg.norm(p-q,axis=1).max()));duration=(r['distance_cells']+8.25)/2.5;old_speed.append(prev['route']['total_length']/duration);new_speed.append(r['route']['total_length']/duration)
 assert r['path']==prev['path'] and r['distance_cells']==prev['distance_cells']
 assert np.linalg.norm(np.array(r['route']['start_position'])-[345,1095])<1e-6
 assert np.linalg.norm(np.array(r['route']['end_position'])-np.array(prev['route']['end_position']))<.001
for y in range(15):
 for x in range(16):assert np.linalg.norm(np.array(a.D['plane_centers'][f'{x},{y}'])-old['plane_centers'][f'{x},{y}'])<.001
# Route arc distance is approximated by 12 chords per Bezier. Bound the exact
# derivative on each interpolated t interval, not merely total/duration.
peak_speed=0.;max_arc_ratio=1.;peak_depth_speed=0.
for r in a.D['records']:
 ratio=1.;depth_ratio=0.
 for seg in r['route']['segments']:
  la,lb,lc=[np.array(seg[k]) for k in ['logical_a','logical_b','logical_c']]
  if not seg['curved']:
   depth_ratio=max(depth_ratio,.008*abs(lc[1]-la[1])/seg['length']);continue
  dys=np.abs(2*((lb[1]-la[1])*(1-np.linspace(0,1,13))+(lc[1]-lb[1])*np.linspace(0,1,13)));depth_ratio=max(depth_ratio,float(np.max(np.maximum(dys[:-1],dys[1:])/(12*np.diff(seg['arc_lengths']))))*.008)
  pa,pb,pc=[np.array(seg[k]) for k in ['a','b','c']];ts=np.linspace(0,1,13)[:,None];derivative=np.linalg.norm(2*((pb-pa)*(1-ts)+(pc-pb)*ts),axis=1);chords=np.diff(seg['arc_lengths']);ratio=max(ratio,float(np.max(np.maximum(derivative[:-1],derivative[1:])/(12*chords))))
 max_arc_ratio=max(max_arc_ratio,ratio);speed=r['route']['total_length']/((r['distance_cells']+8.25)/2.5);peak_speed=max(peak_speed,ratio*speed);peak_depth_speed=max(peak_depth_speed,depth_ratio*speed)
foot_radius=max(np.linalg.norm(c.bounded(q,f,np.array([0.]),False,True),axis=-1).max() for f,q in enumerate(a.SHAPES));depth_allowance=foot_radius*peak_depth_speed/120
assert depth_allowance+.0002<.02
margin=peak_speed/120+.02
report={'method':'Actual Godot 4.6.3 updated production Rules and CarrierRoute export, then 120 Hz heading/rate-limit/hysteresis and 37 pickup-turn samples. Source-alpha foot-pad hulls plus bounded all-phase shader displacements: both weighted groups cannot exceed the stride convex hull. Contains current 3/4/6 visible leg metadata. No body, antennae, carried-ball, or whole-sprite ellipse used as foot contacts. Half-pixel AA pad is already deducted.','first_level_only':True,'result':result,'coverage':{'routes':369,'distinct_resource_targets':240,'peel_geometry_layers':8,'authored_rules_result':a.D['authored_status'],'authored_rules_time_us':a.D['authored_time_us'],'later_levels':False,'GL':False},'route_equivalence':{'all_logical_paths_and_distances_unchanged':True,'all_240_resource_centers_unchanged':True,'all_nest_and_resource_endpoints_unchanged':True,'production_sample_port_max_error_px':max(errors),'length_change_px':[min(delta),max(delta)],'maximum_outbound_speed_px_sec_before_after':[max(old_speed),max(new_speed)],'max_relative_screen_speed_reduction_percent':-min(np.array(new_speed)/old_speed-1)*100,'rules_timings_budget_rewards_edited':False},'sampling_depth_scale_allowance_px':depth_allowance,'sampling_max_screen_speed_px_sec':peak_speed,'arc_interpolation_max_derivative_ratio':max_arc_ratio,'sampling_allowance_px':margin,'conservative_clearance_after_full_frame_movement_allowance':{'planar_ground':result['worst']['ground']['clearance']-margin,'lifted_foot_projection':result['worst']['projected']['clearance']-margin},'nest_gateway_board':{'nest':[345,1095],'gateway':[467,940],'entrance_cell':[8,15],'entrance_position':a.D['plane_centers']['8,15'],'screen_approach_length_px':sum(s['length'] for s in a.D['records'][0]['route']['segments'][:2]),'unchanged_declared_approach_cells':8.25,'unload_at_nest':True,'hopper':[452,1097],'nest_to_hopper_gap_px':math.hypot(452-345,1097-1095),'hopper_note':'The carrier route ends at nest; there is no carrier route continuation to the hopper. A separate visible transfer is not established by this geometry audit.'},'limitations':['Every resource target is covered, but this is not exhaustive enumeration of all 2^240 possible occupancy topologies.','The walkable polygon is a declared geometry contract, not a segmented ground texture mask.','Dragon distance is to its baked centerline, not a tested visible alpha silhouette or temporal collision.','Foot pixels and sphere image overlap are depth/occlusion questions; no full 3D collision volume is defined here.','120 Hz plus one-frame movement allowance covers this fixed-speed geometric sample, not independent real-device frame jitter, upgraded movement, or human visual gait acceptance.'],'hashes':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in ['assets/first-level/slender-ants.png','assets/first-level/slender-ants.json','scripts/first_level_carrier.gd','scripts/first_level_carrier.gdshader','scripts/carrier_route.gd','scripts/board_plane.gd','scripts/rescue_rules.gd','data/scenes/first-level-approved.json','data/serpent-levels/serpent-01.json']}}
assert report['conservative_clearance_after_full_frame_movement_allowance']['planar_ground']>0
assert report['conservative_clearance_after_full_frame_movement_allowance']['lifted_foot_projection']>0
(OUT/'audit_footpath_integrated.json').write_text(json.dumps(report,indent=2));print(json.dumps({k:v for k,v in report.items() if k not in ['result','hashes']},indent=2))
