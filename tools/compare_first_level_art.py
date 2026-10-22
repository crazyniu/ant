#!/usr/bin/env python3
"""Create explicitly labeled, CPU-only comparison evidence. Source art unchanged."""
from pathlib import Path
import json,subprocess
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'reports/first-level/batch-2';FONT=str(ROOT/'assets/fonts/Title.ttf')
f=ImageFont.truetype(FONT,22);small=ImageFont.truetype(FONT,17)
# Three complete pages. Runtime panels use actual node positions from each version.
canvas=Image.new('RGB',(1440,960),'#e5dcc8');d=ImageDraw.Draw(canvas)
for col,(name,file) in enumerate([('APPROVED FIRST LEVEL',ROOT/'reports/first-level/approved-battle.jpeg'),('BEFORE: OFFLINE NODES',OUT/'before-walking-offline.png'),('AFTER: OFFLINE NODES',OUT/'after-walking-offline.png')]):
 im=Image.open(file).convert('RGB');im.thumbnail((460,855),Image.Resampling.LANCZOS);canvas.paste(im,(col*480+(480-im.width)//2,60));d.text((col*480+15,15),name,font=f,fill='#332919')
d.text((15,925),'Not Godot/GL. 8s node snapshots. Shader tint approximate; leg warp, FX and native text not rendered.',font=small,fill='#332919');canvas.save(OUT/'reference-before-after.png')
# Eight-view anatomical contacts, using current metadata with unchanged raster.
m=json.loads((ROOT/'assets/first-level/slender-ants.json').read_text());atlas=Image.open(ROOT/'assets/first-level/slender-ants.png').convert('RGBA');balls=Image.open(ROOT/'assets/first-level/round-beads.png').convert('RGBA');r=json.loads((ROOT/'assets/first-level/bead-regions.json').read_text())['blue'];ball=balls.crop((r[0],r[1],r[0]+r[2],r[1]+r[3]));scale=62/420;mag=4;panel=310;rowh=340
out=Image.new('RGB',(panel*8,rowh*2+120),'#bd9966');d=ImageDraw.Draw(out)
d.text((16,10),'OFFLINE CONTACT STUDY / NOT GODOT OR GL / 4x enlargement / same 33.5 ball and 62 model width',font=f,fill='black')
for i,p in enumerate(m['poses']):
 x,y,w,h=p['region'];sprite=atlas.crop((x,y,x+w,y+h)).resize((round(w*scale*mag),round(h*scale*mag)),Image.Resampling.LANCZOS);b=ball.resize((round(33.5*mag),round(33.5*mag)),Image.Resampling.LANCZOS);foot=p['foot_anchor']
 for row in (0,1):
  ox=i*panel+panel//2;oy=365+row*rowh
  out.paste(sprite,(round(ox-foot[0]*scale*mag),round(oy-foot[1]*scale*mag)),sprite)
  anchor=[0,-62*.63] if row==0 else [(p['cargo_bottom_contact'][0]-foot[0])*scale,(p['cargo_bottom_contact'][1]-foot[1])*scale]
  out.paste(b,(round(ox+(anchor[0]-33.5*.5)*mag),round(oy+(anchor[1]-33.5)*mag)),b)
  d.text((i*panel+15,60+row*rowh),p['name']+(' BEFORE' if row==0 else ' BACK CONTACT'),font=f,fill='black')
  d.ellipse((ox-3,oy-3,ox+3,oy+3),fill='#c40000')
d.text((16,755),'Only attachment placement changes. Ball highlights/material and full animation still require correction / real visual acceptance.',font=f,fill='black');out.save(OUT/'cargo-before-after.png')
