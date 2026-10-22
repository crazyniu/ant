#!/usr/bin/env python3
"""Reproduce alpha>127 toe measurements and the old/new endpoint overlay."""
import json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
from audit_footpath_geometry import TOES
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'reports/first-level/batch-2'
im=Image.open(ROOT/'assets/first-level/slender-ants.png').convert('RGBA');arr=np.array(im);m=json.loads((ROOT/'assets/first-level/slender-ants.json').read_text())
# Source-pixel starts on the corresponding visible limb, not inside an occluded
# abdomen. Count-aware shader plumbing enables S=6/NW=NE=3 visible legs.
HIPS={
'E':[[176,244],[236,251],[209,248],[266,239]],
'SE':[[132,185],[181,218],[141,218],[265,197]],
'S':[[94,205],[85,250],[108,242],[185,241],[208,250],[211,205]],
'SW':[[128,202],[161,217],[241,207],[288,183]],
'W':[[141,228],[208,233],[231,234],[203,240]],
'NW':[[124,230],[153,245],[195,250]],
'N':[[95,196],[106,254],[196,254],[211,194]],
'NE':[[187,249],[221,250],[260,217]]}
previous_path=OUT/'audit_footpath_measured_endpoints.json'
previous=json.loads(previous_path.read_text()) if previous_path.exists() else {'poses':[]}
old_by_name={p['name']:p.get('old_legs',[]) for p in previous['poses']}
report={'method':'Manually selected visible distal toe-pad ROIs, checked on 2x pixel grid; centroid/bounds use alpha>=128 only, excluding semi-transparent blue fringe and background shadow. Short proximal toe pixels may remain conservatively. Tips are not a measurement of foot_anchor; no ant/ball scaling changes.','poses':[]}
out=Image.new('RGB',(1600,900),(176,176,176));draw=ImageDraw.Draw(out)
for i,p in enumerate(m['poses']):
 x,y,w,h=p['region'];v=arr[y:y+h,x:x+w];centers=[];details=[]
 for roi in TOES[p['name']]:
  a,b,c,d=roi;yy,xx=np.where(v[b:d,a:c,3]>=128);q=np.c_[xx+a,yy+b];center=np.round(q.mean(0),2).tolist();centers.append(center);details.append({'roi':list(roi),'center':center,'alpha_bounds':[q.min(0).tolist(),q.max(0).tolist()],'solid_pixel_count':len(q)})
 legs=[hip+center for hip,center in zip(HIPS[p['name']],centers)]
 report['poses'].append({'name':p['name'],'old_legs':old_by_name.get(p['name'],p['legs']),'suggested_visible_legs':legs,'leg_groups':([0,1,0,1,0,1] if p['name']=='S' else ([0,1,0,1] if p['name']=='N' else ([0,1,0] if p['name'] in ['NW','NE'] else [0,0,1,1]))),'visible_toe_count':len(legs),'foot_anchor_unchanged':p['foot_anchor'],'measurements':details})
 cell=Image.new('RGBA',(400,450),(176,176,176,255));crop=im.crop((x,y,x+w,y+h));crop.thumbnail((390,400));cell.alpha_composite(crop,(0,30));d=ImageDraw.Draw(cell);sx=crop.width/w;sy=crop.height/h
 for j,leg in enumerate(old_by_name.get(p['name'],p['legs'])):
  px=leg[2]*sx;py=leg[3]*sy+30;d.ellipse([px-5,py-5,px+5,py+5],outline=(255,30,50),width=2);d.text((px+5,py),str(j),fill=(255,30,50))
 for j,leg in enumerate(legs):
  px=leg[2]*sx;py=leg[3]*sy+30;d.ellipse([px-5,py-5,px+5,py+5],outline=(10,255,100),width=2);d.text((px+5,py-12),str(j),fill=(10,255,100))
 d.text((5,5),p['name']+' old=red new=green',fill='black');out.paste(cell.convert('RGB'),((i%4)*400,(i//4)*450))
out.save(OUT/'audit_footpath_corrected_endpoint_overlay.png');(OUT/'audit_footpath_measured_endpoints.json').write_text(json.dumps(report,indent=2))
print(json.dumps({p['name']:p['suggested_visible_legs'] for p in report['poses']},indent=2))
