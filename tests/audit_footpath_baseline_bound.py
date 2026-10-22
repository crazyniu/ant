#!/usr/bin/env python3
"""Geometry-only A/B: current corrected visible feet on archived original routes."""
import json,hashlib
import numpy as np
from scipy.spatial import cKDTree
import audit_footpath_geometry as a
from audit_footpath_candidate import bounded
a.M=json.loads((a.ROOT/'assets/first-level/slender-ants.json').read_text());a.L=json.loads((a.ROOT/'data/scenes/first-level-approved.json').read_text());a.D=json.loads((a.OUT/'audit_footpath_baseline_routes.json').read_text());a.H=np.array(a.L['walkable_polygon']);a.DIST=cKDTree(a.D['dragon_baked_points']);a.SHAPES,meta=a.shapes();a.deformed=bounded
r={'method':'Current corrected production toe metadata, identical all-phase bound as integrated report, 120 Hz; only route geometry is reverted to the archived pre-change production export. This is a controlled geometry A/B, not a rerun of the old rendered game.','result':a.audit(a.D['records'],'baseline_route_bound',120),'hashes':{p:hashlib.sha256((a.ROOT/p).read_bytes()).hexdigest() for p in ['assets/first-level/slender-ants.json','reports/first-level/batch-2/audit_footpath_baseline_routes.json']}}
(a.OUT/'audit_footpath_baseline_bound.json').write_text(json.dumps(r,indent=2));print(json.dumps(r['result']['worst'],indent=2))
