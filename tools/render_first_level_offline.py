#!/usr/bin/env python3
"""Deterministic engineering composition of exported nodes, NOT Godot rendering.
No source art is edited. Shader recolor is approximated in sRGB; limb warp,
particles and native font/layout filtering require actual GL comparison.
"""
import json, math, pathlib, argparse
import numpy as np
from PIL import Image, ImageDraw, ImageFont
ROOT=pathlib.Path(__file__).resolve().parents[1]
SIZE=(940,1672)
def smooth(a,b,x):
 t=np.clip((x-a)/(b-a),0,1);return t*t*(3-2*t)
def paint_shader(im,item):
 if not item.get('tint'):return im
 v=np.array(im,dtype=float)/255;c=v[:,:,:3]; tint=np.array(item['tint'][:3]);s=item.get('shader','');value=c.max(2)
 if 'combat_tint' in s:
  if item.get('tint_all'):
   neutral=c@np.array([.299,.587,.114]);p=tint*(.4+.6*neutral[:,:,None]);h=smooth(.8,.99,neutral)*.22;p=p*(1-h[:,:,None])+neutral[:,:,None]*h[:,:,None];mask=np.ones(value.shape)
  else:
   mask=smooth(.08,.3,c[:,:,0]-np.maximum(c[:,:,1]*1.2,c[:,:,2]*1.2));h=np.minimum(c[:,:,1],c[:,:,2])*.35;p=tint*value[:,:,None]*(1-h[:,:,None])+value[:,:,None]*h[:,:,None]
 else:
  carrier='carrier' in s
  mask=smooth(.025 if carrier else .035,.16 if carrier else .19,c[:,:,2]-np.maximum(c[:,:,0],c[:,:,1]));p=tint/max(tint.max(),.001)*value[:,:,None];h=smooth(.6 if carrier else .62,.98,np.minimum(c[:,:,0],c[:,:,1]));p=p*(1-h[:,:,None])+value[:,:,None]*h[:,:,None]
  if carrier:mask*=smooth(.08,.30,value-c.min(2))
 v[:,:,:3]=c*(1-mask[:,:,None])+p*mask[:,:,None]
 return Image.fromarray(np.uint8(np.clip(v,0,1)*255))
def stamp(canvas,im,item):
 a,b,c,d,e,f=item['matrix'];w,h=item['size'];iw,ih=im.size
 if not w or not h:return
 A=a*w/iw;B=b*w/iw;C=c*h/ih;D=d*h/ih
 corners=[(e,f),(e+A*iw,f+B*iw),(e+C*ih,f+D*ih),(e+A*iw+C*ih,f+B*iw+D*ih)]
 l=max(0,math.floor(min(q[0] for q in corners)));t=max(0,math.floor(min(q[1] for q in corners)));r=min(canvas.width,math.ceil(max(q[0] for q in corners)));bt=min(canvas.height,math.ceil(max(q[1] for q in corners)))
 det=A*D-B*C
 if r<=l or bt<=t or abs(det)<1e-12:return
 coeff=(D/det,-C/det,(D*(l-e)-C*(t-f))/det,-B/det,A/det,(-B*(l-e)+A*(t-f))/det)
 im=im.transform((r-l,bt-t),Image.Transform.AFFINE,coeff,Image.Resampling.BICUBIC)
 mod=np.array(item.get('modulate',[1,1,1,1]));im=Image.fromarray(np.uint8(np.array(im)*mod))
 canvas.alpha_composite(im,(l,t))
def compose(path):
 data=json.loads(path.read_text());can=Image.new('RGBA',SIZE);ignored=[];cache={}
 for item in data['nodes']:
  typ=item['type'];w,h=item['size']
  if typ=='texture':
   p=ROOT/item['path'].removeprefix('res://')
   if p not in cache:cache[p]=Image.open(p).convert('RGBA')
   x,y,rw,rh=item['region'];im=cache[p].crop((round(x),round(y),round(x+rw),round(y+rh)));im=paint_shader(im,item);stamp(can,im,item)
  elif typ=='shadow':
   rx,ry=item['radius'];im=Image.new('RGBA',(max(1,math.ceil(rx*2)),max(1,math.ceil(ry*2))))
   # The draw node's local origin is the ellipse center, not the control corner.
   draw=ImageDraw.Draw(im)
   for i in range(6,0,-1):
    k=i/6;draw.ellipse((rx*(1-k),ry*(1-k),rx*(1+k),ry*(1+k)),fill=(59,33,11,round(item['strength']/6*255*(7-i))))
   it=item.copy();a,b,c,d,e,f=it['matrix'];it['matrix']=[a,b,c,d,e-a*rx-c*ry,f-b*rx-d*ry];it['size']=[rx*2,ry*2];stamp(can,im,it)
  elif typ=='label':
   if w<=0 or h<=0:continue
   im=Image.new('RGBA',(max(1,round(w)),max(1,round(h))));draw=ImageDraw.Draw(im);font=ImageFont.truetype(str(ROOT/'assets/fonts/Title.ttf'),item['font_size']);color=tuple(round(v*255) for v in item['color']);outline=tuple(round(v*255) for v in item['outline_color']);align=item.get('horizontal_alignment',0);x=0 if align==0 else (w*.5 if align==1 else w);anchor='lm' if align==0 else ('mm' if align==1 else 'rm');draw.text((x,h*.5),item['text'],font=font,fill=color,anchor=anchor,stroke_width=item['outline'],stroke_fill=outline);stamp(can,im,item)
  elif typ in ('gear','icon'):
   im=Image.new('RGBA',(max(1,round(w)),max(1,round(h))));draw=ImageDraw.Draw(im);cx,cy=w/2,h/2;kind=item.get('kind','gear_only');ink=(255,222,145,255)
   if kind=='gear_only':
    pts=[(cx+math.cos(i*math.tau/48)*(23 if i%6 in (0,1,4,5) else 18),cy+math.sin(i*math.tau/48)*(23 if i%6 in (0,1,4,5) else 18)) for i in range(48)];draw.polygon(pts,fill=ink);draw.ellipse((cx-10,cy-10,cx+10,cy+10),fill=(101,67,36,255))
   elif kind=='pause':
    r=min(w,h)*.34
    for x in (-.35,.35):draw.rounded_rectangle((cx+x*r-4,cy-r,cx+x*r+4,cy+r),radius=4,fill=ink)
   else:ignored.append(item['name'])
   stamp(can,im,item)
  else:ignored.append(item['name'])
 return can,data,ignored
if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('nodes');ap.add_argument('output');args=ap.parse_args();can,data,ignored=compose(pathlib.Path(args.nodes));can.convert('RGB').save(args.output);print(json.dumps({'not_godot_render':True,'nodes':args.nodes,'output':args.output,'omitted_custom_icons':ignored,'approximation':'sRGB recolor, static limb pixels, Pillow text/filtering; no GL, shader warp or particles'},indent=2))
