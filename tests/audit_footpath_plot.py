#!/usr/bin/env python3
"""Analytical geometry figure; not a GL screenshot or game-art edit."""
import json
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon,Circle
import audit_footpath_geometry as a
import audit_footpath_candidate as c
a.M=json.loads((a.ROOT/'assets/first-level/slender-ants.json').read_text());a.L=json.loads((a.ROOT/'data/scenes/first-level-approved.json').read_text());a.D=json.loads((a.OUT/'audit_footpath_baseline_routes.json').read_text());a.H=np.array(a.L['walkable_polygon']);a.SHAPES,_=a.shapes()
for x in range(16):c.OVERRIDES[f'{x},-1'][0]=a.D['plane_centers'][f'{x},-1'][0]
r=json.loads((a.OUT/'audit_footpath_integrated.json').read_text());old=json.loads((a.OUT/'audit_footpath_baseline_bound.json').read_text());current=json.loads((a.OUT/'audit_footpath_production_routes.json').read_text());newmap={json.dumps(v['path']):v for v in current['records']}
fig,ax=plt.subplots(figsize=(9.4,11.5),dpi=160);ax.set_aspect('equal');ax.set_xlim(90,910);ax.set_ylim(1170,100);ax.set_facecolor('#f4f3e9');ax.add_patch(Polygon(a.H,facecolor='#e4ead5',edgecolor='#536b39',lw=1.5,label='Declared walkable ground'))
config=json.loads((a.ROOT/'data/serpent-levels/serpent-01.json').read_text());colors={'P':'#9d68c9','G':'#7dba64','B':'#659dc6','R':'#cd7667','Y':'#d9c45c'}
for y,row in enumerate(config['grid']):
 for x,col in enumerate(row):ax.add_patch(Circle(a.D['plane_centers'][f'{x},{y}'],16.75,fc=colors[col],ec='white',lw=.2,alpha=.7))
dragon=np.array(a.D['dragon_baked_points']);ax.plot(*dragon.T,color='#9a5739',lw=3,label='Dragon centerline (not silhouette)')
for target in [(0,0),(8,0),(15,0),(0,14),(15,14)]:
 entry=next(v for v in a.D['records'] if tuple(v['path'][-1])==target and 'initial' in v['sources']);p,*_=a.sample(entry['route'],np.linspace(0,1,1600));q,*_=a.sample(newmap[json.dumps(entry['path'])]['route'],np.linspace(0,1,1600));ax.plot(*p.T,color='#dd4c48',lw=.7,alpha=.65);ax.plot(*q.T,color='#087ec0',lw=1,alpha=.8)
for key,color in [('ground','#bd3434')]:
 bad=old['result']['worst'][key];ax.scatter(*bad['foot_pixel'],s=40,c=color,zorder=10);ax.annotate('Old route bound: -7.75 px',bad['foot_pixel'],xytext=(560,265),arrowprops={'arrowstyle':'->'},fontsize=9,color=color)
new=r['result']['worst']['ground'];ax.scatter(*new['foot_pixel'],s=40,c='#006d8d',zorder=10);ax.annotate('New production ground: +3.03 px',new['foot_pixel'],xytext=(495,290),arrowprops={'arrowstyle':'->'},fontsize=9,color='#006d8d')
for k,p in c.OVERRIDES.items():
 if k in ['-1,-1','16,-1','16,0','16,15']:ax.plot(*p,'o',ms=3,c='#087ec0')
ax.scatter(*a.L['nest']['position'],s=55,c='#8b4e23');ax.text(320,1125,'Nest / unload\n(345,1095)',fontsize=8)
ax.scatter(*a.L['cannon']['hopper'],s=35,c='#888');ax.annotate('Hopper: separate 107.02 px visual link',a.L['cannon']['hopper'],xytext=(500,1080),arrowprops={'arrowstyle':'->'},fontsize=8)
ax.plot([],[],color='#dd4c48',label='Archived original carrier paths');ax.plot([],[],color='#087ec0',label='New production: exterior offsets + 12px rounds')
ax.legend(loc='lower right',fontsize=7);ax.set_title('FIRST-LEVEL FOOTPATH GEOMETRY\nAnalytical plot, not Godot rendering or visual acceptance',fontsize=11);ax.set_xlabel('Logical screen x (px)');ax.set_ylabel('Logical screen y (px)');fig.tight_layout();fig.savefig(a.OUT/'audit_footpath_geometry_overlay.png')
