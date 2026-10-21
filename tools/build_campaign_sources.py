#!/usr/bin/env python3
"""Thirty original, deterministic bead motifs. Generates drafts, never runtime levels.
Geometry is authoring-only; all reachability, choices and timing are Godot Rules.
Run from project root: python tools/build_campaign_sources.py [--through 30]
"""
from pathlib import Path
import argparse, json, math
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'data/campaign-drafts'
PALETTE = dict(R='red', B='blue', Y='yellow', G='green', P='purple', W='white')

class Canvas:
    def __init__(self, w=18, h=18): self.w=w; self.h=h; self.g=[['.']*w for _ in range(h)]
    def dot(self,x,y,c):
        if 0<=x<self.w and 0<=y<self.h: self.g[y][x]=c
        return self
    def rect(self,x0,y0,x1,y1,c):
        for y in range(y0,y1+1):
            for x in range(x0,x1+1): self.dot(x,y,c)
        return self
    def ellipse(self,x0,y0,x1,y1,c):
        rx=(x1-x0+1)/2; ry=(y1-y0+1)/2; cx=(x0+x1)/2; cy=(y0+y1)/2
        for y in range(y0,y1+1):
            for x in range(x0,x1+1):
                if ((x-cx)/rx)**2+((y-cy)/ry)**2<=1: self.dot(x,y,c)
        return self
    def poly(self,points,c):
        for y in range(self.h):
            for x in range(self.w):
                inside=False; j=len(points)-1
                for i,(xi,yi) in enumerate(points):
                    xj,yj=points[j]
                    if (yi>y)!=(yj>y) and x<(xj-xi)*(y-yi)/(yj-yi)+xi: inside=not inside
                    j=i
                if inside: self.dot(x,y,c)
        return self
    def line(self,x0,y0,x1,y1,c,width=1):
        steps=max(abs(x1-x0),abs(y1-y0),1)
        for i in range(steps+1):
            x=round(x0+(x1-x0)*i/steps); y=round(y0+(y1-y0)*i/steps)
            self.rect(x-width//2,y-width//2,x+(width-1)//2,y+(width-1)//2,c)
        return self
    def rows(self): return [''.join(row) for row in self.g]

# Each composition has its own silhouette and internal regions, not a recolored mask.
def sprout():
    a=Canvas(12,12); a.ellipse(1,1,6,5,'G').ellipse(6,2,10,6,'G').line(6,4,6,9,'G').rect(3,9,9,10,'G'); return a

def sunrise():
    a=Canvas(14,14); a.ellipse(3,2,10,9,'Y');
    for x,y in [(1,2),(6,0),(12,2),(0,6),(13,6)]: a.dot(x,y,'Y')
    a.line(2,10,11,10,'B').line(0,12,6,12,'B').line(8,13,13,13,'B'); return a

def lantern():
    a=Canvas(14,16); a.rect(5,0,8,1,'Y').rect(3,2,10,3,'Y').ellipse(2,3,11,11,'R').rect(5,4,8,10,'Y').rect(4,12,9,12,'Y').line(6,13,6,15,'R').line(8,13,8,15,'R'); return a

def sailboat():
    a=Canvas(16,16); a.line(8,1,8,11,'Y').poly([(7,2),(1,9),(7,9)],'W').poly([(9,3),(14,9),(9,9)],'Y').poly([(1,11),(15,11),(12,14),(4,14)],'B').line(1,15,6,15,'B').line(10,15,14,15,'B'); return a

def strawberry():
    a=Canvas(16,16); a.ellipse(2,3,13,11,'R').poly([(3,8),(13,8),(8,16)],'R').poly([(3,2),(7,3),(8,0),(10,3),(14,2),(11,5),(5,5)],'G')
    for x,y in [(5,6),(10,6),(3,9),(8,9),(11,10),(7,12)]: a.dot(x,y,'Y')
    return a

def compass():
    a=Canvas(); a.ellipse(2,2,15,15,'B').ellipse(4,4,13,13,'W').poly([(9,0),(11,7),(17,9),(10,11),(8,17),(6,10),(0,8),(7,6)],'Y').poly([(9,2),(9,9),(6,9)],'R').dot(9,9,'B'); return a

def cottage():
    a=Canvas(); a.rect(3,8,14,16,'Y').poly([(1,9),(8,1),(17,9)],'R').rect(12,1,13,5,'W').rect(5,11,7,13,'B').rect(10,10,12,16,'G').line(2,17,15,17,'G'); return a

def butterfly():
    a=Canvas(); a.ellipse(0,2,7,9,'P').ellipse(10,2,17,9,'P').ellipse(2,9,7,15,'Y').ellipse(10,9,15,15,'Y').ellipse(2,4,5,7,'B').ellipse(12,4,15,7,'B').line(8,4,8,15,'R').line(9,4,9,15,'R').line(8,3,5,0,'R').line(9,3,12,0,'R'); return a

def frog():
    a=Canvas(); a.ellipse(3,1,7,6,'G').ellipse(10,1,14,6,'G').ellipse(2,5,15,13,'G').rect(4,3,5,4,'W').rect(12,3,13,4,'W').ellipse(5,8,12,13,'Y').line(5,7,12,7,'R').ellipse(0,12,5,16,'G').ellipse(12,12,17,16,'G').line(3,17,14,17,'B'); return a

def bell():
    a=Canvas(); a.ellipse(6,0,11,4,'G').ellipse(3,3,14,13,'Y').rect(3,10,14,13,'Y').rect(1,14,16,15,'R').ellipse(7,15,10,17,'Y').line(5,5,5,10,'W').rect(7,6,10,11,'B'); return a

def mushrooms():
    a=Canvas(20,18); a.rect(5,8,8,16,'W').rect(14,11,16,16,'W').ellipse(0,1,13,10,'R').rect(0,8,13,10,'R').ellipse(11,6,19,12,'P').dot(3,4,'Y').rect(7,3,9,5,'Y').rect(3,7,4,8,'Y').rect(14,8,15,9,'B').rect(2,17,18,17,'G'); return a

def fox():
    a=Canvas(20,20); a.poly([(1,1),(8,5),(12,5),(19,1),(17,14),(10,19),(3,14)],'R').poly([(3,3),(7,6),(4,9)],'P').poly([(17,3),(13,6),(16,9)],'P').poly([(4,11),(9,13),(10,17),(3,13)],'W').poly([(16,11),(11,13),(10,17),(17,13)],'W').rect(5,9,6,10,'B').rect(13,9,14,10,'B').rect(9,14,10,15,'Y').line(6,19,13,19,'G'); return a

def hummingbird():
    a=Canvas(20,20); a.poly([(4,0),(11,8),(13,14),(7,9)],'G').poly([(0,6),(9,9),(12,14),(5,12)],'B').ellipse(9,7,15,14,'G').ellipse(13,4,17,8,'Y').line(16,5,19,4,'R').poly([(10,13),(9,19),(5,17)],'P').dot(16,5,'W').ellipse(0,15,4,19,'R').dot(2,17,'Y'); return a

def teapot():
    a=Canvas(20,18); a.ellipse(2,4,15,15,'B').ellipse(14,4,19,11,'P').ellipse(16,6,17,9,'.').poly([(4,7),(0,3),(0,10),(4,13)],'B').rect(4,2,13,4,'Y').rect(7,0,10,1,'R').ellipse(5,7,12,13,'W').ellipse(7,8,10,11,'G').rect(4,16,14,17,'Y'); return a

def windmill():
    a=Canvas(20,20); a.poly([(8,9),(12,9),(15,19),(5,19)],'W').rect(8,15,11,18,'B').poly([(8,8),(1,5),(2,1),(9,7)],'R').poly([(10,8),(13,1),(17,2),(11,9)],'Y').poly([(11,10),(18,13),(17,17),(10,11)],'R').poly([(9,11),(6,18),(2,17),(8,10)],'Y').rect(8,8,11,11,'P').line(0,19,19,19,'G'); return a

def crab():
    a=Canvas(20,18); a.ellipse(5,6,14,13,'R').ellipse(0,1,5,6,'R').ellipse(14,1,19,6,'R').rect(2,1,3,2,'.').rect(16,1,17,2,'.').line(3,5,6,9,'Y').line(16,5,13,9,'Y').rect(7,4,8,6,'W').rect(11,4,12,6,'W').dot(7,4,'B').dot(12,4,'B').rect(8,9,11,11,'P')
    for y in [9,12,15]: a.line(5,10,1,y,'G').line(14,10,18,y,'G')
    return a

def acorn():
    a=Canvas(20,20); a.line(10,0,9,3,'G').ellipse(3,3,16,9,'P').ellipse(5,7,14,18,'Y').rect(3,7,16,9,'R').ellipse(7,10,12,16,'W').rect(9,12,10,15,'B').line(2,19,17,19,'G'); return a

def seahorse():
    a=Canvas(20,22); a.ellipse(7,1,15,8,'Y').rect(14,4,19,6,'Y').dot(13,3,'B').ellipse(6,6,12,16,'Y').poly([(6,7),(2,9),(6,12),(2,15),(7,17)],'P').ellipse(7,14,16,21,'R').ellipse(10,16,14,19,'.').rect(12,14,16,17,'R').rect(9,8,11,13,'W').line(1,16,1,21,'G').line(0,19,4,17,'G').dot(17,10,'B').dot(18,13,'B'); return a

def moon_palace():
    a=Canvas(22,20); a.ellipse(1,0,11,10,'Y').ellipse(5,0,13,8,'.').rect(8,10,19,18,'P').rect(6,8,10,17,'B').rect(17,7,21,17,'B').poly([(5,8),(8,3),(11,8)],'R').poly([(16,7),(19,2),(22,7)],'R').rect(11,7,16,10,'W').rect(12,12,15,18,'Y').line(4,19,21,19,'G'); return a

def shell():
    a=Canvas(22,20); a.ellipse(1,1,20,18,'P').ellipse(3,3,18,16,'B').ellipse(5,5,16,15,'G').ellipse(7,7,14,13,'Y').ellipse(9,8,12,11,'R').rect(10,10,11,10,'W').line(10,12,20,18,'Y',2).rect(1,17,5,18,'.').rect(18,1,21,6,'.'); return a

def egg_shrine():
    a=Canvas(22,22); a.ellipse(5,1,16,17,'W').ellipse(7,4,14,14,'P').poly([(10,5),(8,9),(12,10),(10,14),(14,9),(10,8)],'Y').rect(3,17,18,19,'R').rect(1,20,20,21,'B').line(2,5,2,15,'G').line(19,5,19,15,'G').rect(1,4,3,6,'Y').rect(18,4,20,6,'Y'); return a

def owl():
    a=Canvas(22,22); a.poly([(3,0),(9,5),(13,5),(19,0),(19,15),(15,20),(6,20),(2,15)],'P').ellipse(3,5,10,12,'W').ellipse(11,5,18,12,'W').ellipse(5,7,8,10,'B').ellipse(13,7,16,10,'B').poly([(9,11),(13,11),(11,15)],'Y').ellipse(7,14,14,18,'R').rect(7,20,8,21,'Y').rect(13,20,14,21,'Y').line(0,21,21,21,'G'); return a

def bridge():
    a=Canvas(24,20); a.rect(2,9,21,13,'R').ellipse(5,11,10,18,'.').ellipse(13,11,18,18,'.').rect(2,13,4,18,'R').rect(11,13,12,18,'R').rect(19,13,21,18,'R').line(1,7,22,7,'Y').line(2,4,2,9,'P').line(21,4,21,9,'P').ellipse(0,1,4,5,'W').ellipse(19,1,23,5,'W').rect(1,2,3,4,'Y').rect(20,2,22,4,'Y').line(1,19,8,19,'B').line(11,18,17,18,'B').line(18,19,23,19,'B').rect(8,3,9,5,'G').rect(14,3,15,5,'G'); return a

def lighthouse():
    a=Canvas(22,24); a.poly([(8,5),(13,5),(16,20),(5,20)],'W').rect(7,9,14,11,'R').rect(6,15,15,17,'R').rect(7,3,14,6,'B').rect(9,4,12,5,'Y').poly([(6,3),(10,0),(15,3)],'P').poly([(3,20),(18,20),(21,23),(0,23)],'G').rect(9,18,11,20,'B').line(0,13,4,13,'B').line(17,12,21,12,'B'); return a

def phoenix():
    a=Canvas(24,22); a.poly([(0,2),(8,7),(11,4),(13,4),(16,7),(24,2),(21,12),(15,14),(17,21),(12,17),(7,21),(9,14),(3,12)],'R').poly([(2,5),(9,9),(10,13),(5,10)],'Y').poly([(22,5),(15,9),(14,13),(19,10)],'Y').ellipse(10,7,13,15,'W').ellipse(10,2,14,6,'P').dot(13,3,'B').poly([(10,15),(13,15),(12,22)],'G'); return a

def garden():
    a=Canvas(24,22); a.ellipse(2,1,21,20,'G').ellipse(5,4,18,17,'.').rect(2,11,5,20,'G').rect(18,11,21,20,'G').rect(8,12,15,20,'Y').rect(10,14,13,20,'B')
    for x,y,c in [(3,4,'R'),(17,4,'P'),(1,12,'P'),(19,12,'R'),(10,1,'R')]: a.ellipse(x,y,x+3,y+3,c).dot(x+1,y+1,'W')
    a.line(6,21,17,21,'W'); return a

def airship():
    a=Canvas(24,20); a.ellipse(1,1,22,12,'P').ellipse(3,3,20,10,'Y').rect(5,5,18,8,'R').poly([(1,7),(0,13),(5,11)],'B').poly([(22,7),(24,13),(19,11)],'B').line(7,12,9,15,'W').line(16,12,14,15,'W').rect(8,15,15,18,'G').rect(9,16,10,17,'B').rect(13,16,14,17,'B').dot(2,18,'W').dot(21,16,'W'); return a

def citadel():
    a=Canvas(24,24); a.rect(3,11,20,21,'B').rect(1,7,5,20,'W').rect(18,7,22,20,'W').rect(9,5,14,21,'P').poly([(0,7),(3,1),(6,7)],'R').poly([(17,7),(20,1),(23,7)],'R').poly([(8,5),(12,0),(16,5)],'Y').rect(10,14,13,21,'Y').rect(6,13,7,15,'G').rect(16,13,17,15,'G').rect(1,22,22,23,'G').rect(2,9,3,11,'B').rect(20,9,21,11,'B'); return a

def orchid_dragon():
    a=Canvas(24,24); a.ellipse(8,3,18,11,'G').rect(16,5,22,8,'G').rect(19,4,20,5,'Y').dot(18,6,'B').ellipse(5,9,14,21,'G').ellipse(8,12,11,18,'W').poly([(6,9),(0,3),(2,14),(6,17)],'P').poly([(12,10),(22,10),(17,17),(13,17)],'P').poly([(8,19),(6,24),(17,22),(14,19)],'Y').ellipse(0,17,5,22,'R').dot(2,19,'Y').line(2,21,1,23,'B').rect(11,1,12,4,'R').rect(15,1,16,4,'R'); return a

def crown():
    a=Canvas(24,24); a.poly([(1,3),(7,10),(12,1),(17,10),(23,3),(20,17),(4,17)],'Y').rect(4,16,19,19,'R').rect(5,20,18,21,'Y').ellipse(9,10,14,15,'B').rect(5,12,6,14,'P').rect(17,12,18,14,'G').dot(1,2,'W').dot(12,0,'W').dot(23,2,'W').line(4,23,9,23,'W').line(14,23,19,23,'W'); return a

# Teaching objectives, lane order, armor order and quotas are independent authoring choices.
SPECS = [
(sprout,'First Sprout','One exposed color: select, exhaust quota, wait for delivery and final hit.','G','G',12,1),
(sunrise,'Sunrise Ripples','Two separated regions: future blue stock survives yellow armor.','BY','YB',12,1),
(lantern,'Paper Lantern','Open red sides before the enclosed yellow light; extra slot first available.','RY','RY',14,1),
(sailboat,'Little Sailboat','Three exposed choices and a small last wave; quota zero is not victory.','BWY','YBW',12,1),
(strawberry,'Seeded Strawberry','Green crown and red fruit expose small yellow seeds; basic waiting.','GRY','RGY',14,1),
(compass,'Wayfinder Compass','Queue order differs from armor: hold white stock and clear yellow spokes.','BYRW','RYBW',13,2),
(cottage,'Candy Cottage','Roof and base expose door and window; reserve a slot for blue window quota.','RYGWB','BYRGW',14,2),
(butterfly,'Ribbon Butterfly','Split wings and antennae need different queues; purple opens blue centers.','PYRB','BPYR',13,2),
(frog,'Lily Pond Frog','Select a blocked belly early only if an outer-green slot stays free.','GBWYR','YWGBR',14,2),
(bell,'Harbor Bell','Blue enamel is enclosed by yellow: plan inventory rather than armor-matching clicks.','YRGWB','BYRGW',14,2),
(mushrooms,'Mushroom Grove','Two caps unlock stems and spots; independent quotas share five slots.','RPGWYB','YPRWGB',15,2),
(fox,'Lantern Fox','Ear, eye and muzzle layers; do not overfill slots with the outer fur color.','RPWBYG','BWRPGY',15,2),
(hummingbird,'Hummingbird Visit','Separated flower and bird regions; six-color queue with two destinations.','GBYPWR','PRGBYW',14,2),
(teapot,'Jade Teapot','Handle hole remains enclosed; clear blue body before white and green medallion.','BYPWRG','GWBRYP',15,2),
(windmill,'Orchard Windmill','Four blades and tower overlap; split red/yellow quotas across repeated armor.','RYWPBG','PRYWBG',15,2),
(crab,'Tidepool Crab','Claws, legs and eye stalks expose the shell; scout unlock is optional.','RYGWBP','PRBWGY',14,2),
(acorn,'Acorn Gateway','Cap overlaps nut shell, then white inset and blue center: three exposure steps.','PRYWBG','BWRPYG',15,3),
(seahorse,'Coral Seahorse','Curved tail and body channels; keep a slot for the last blue bubbles.','YRPWGB','WYPRBG',14,3),
(moon_palace,'Moonlit Palace','Crescent and twin towers; white roof and yellow gate release on different paths.','YBPRWG','WPYBGR',16,3),
(shell,'Rainbow Spiral Shell','Six nested colored bands with a diagonal opening; repeated demands store surplus.','PBGYRW','RWPBGY',16,3),
(egg_shrine,'Dragon Egg Shrine','Outer egg, purple core and yellow lightning share attention with two side pillars.','WRPBYG','PYWBRG',15,3),
(owl,'Clockwork Owl','White eye rings enclose blue pupils while body unlocks the red breast.','PWBYRG','BYPRWG',15,3),
(bridge,'Festival Bridge','Three supports and two lanterns; delayed colors stockpile ahead of alternating armor.','RYWPBG','GPRYBW',14,3),
(lighthouse,'Reef Lighthouse','Striped tapering tower; independent top lamp and base route challenge order.','WRBGYP','YPRBWG',15,3),
(phoenix,'Phoenix Crest','Split wing feathers and inner chest; keep slots cycling while armor changes.','RYPWBG','PWRYBG',15,3),
(garden,'Secret Garden Gate','Ring hedge encloses courtyard; flowers interrupt layers and gate stock waits.','GRPWYB','BWRPGY',15,3),
(airship,'Cloudberry Airship','Three nested balloon bands plus suspended gondola; stock different armor colors early.','PYRBWG','RGPYBW',16,3),
(citadel,'Crystal Citadel','Three towers, two windows and enclosed gate: multi-object quota planning.','WRBPYG','PYBWRG',16,3),
(orchid_dragon,'Orchid Guardian','Wings, jaw and belly occupy different channels; six-color endgame cadence.','GPYWRB','BWGPRY',16,3),
(crown,'Rescue Crown','Crown points expose three gems; combine queue planning, split quotas and final flight.','YRPBGW','BPGYRW',15,3),
]

def chunks(total, cap, phase):
    out=[]
    while total:
        q=min(total, max(5, cap-((len(out)+phase)%3)*2)); out.append(q); total-=q
    return out

def build(n,spec):
    draw,name,goal,lane_order,armor_order,cap,armor_parts=spec
    a=draw(); grid=a.rows(); counts={c:sum(row.count(s) for row in grid) for s,c in PALETTE.items()}
    active=[s for s in lane_order if counts[PALETTE[s]]]
    assert set(active)=={s for s,c in PALETTE.items() if counts[c]}, (n,active,counts)
    columns=[{'id':f'column-{i+1}','teams':[]} for i in range(5)]
    # First fronts follow the authored exposure order. Later quota slices move
    # between lanes, so choosing a front also exposes a different future color.
    groups=[]
    for i,symbol in enumerate(active):
        color=PALETTE[symbol]
        groups.append([{'id':f'{color}-{k+1:02}','color':color,'quota':q}
                       for k,q in enumerate(chunks(counts[color],cap,(n+i)%3))])
    if n<=5:
        for i,group in enumerate(groups): columns[min(i,4)]['teams'].extend(group)
    else:
        for i,group in enumerate(groups): columns[min(i,4)]['teams'].append(group[0])
        for depth in range(1,max(map(len,groups))):
            for i,group in enumerate(groups):
                if depth<len(group): columns[(i+depth+(n%2))%5]['teams'].append(group[depth])
    armors=[]
    # Interleaved per-color armor slices differ deliberately from team chunk sizes.
    demands={}
    for s in armor_order:
        count=counts[PALETTE[s]]
        if count: demands[s]=[count//min(armor_parts,count)+(1 if j<count%min(armor_parts,count) else 0) for j in range(min(armor_parts,count))]
    for part in range(armor_parts):
        order=armor_order if part%2==0 else armor_order[::-1]
        for s in order:
            if s in demands and part<len(demands[s]):
                armors.append({'id':f'armor-{len(armors)+1:02}','color':PALETTE[s],'demand':demands[s][part]})
    beads=sum(counts.values()); teams=sum(len(x['teams']) for x in columns)
    cooldown=[1.8,2.1,2.4,2.7][0 if n<=5 else 1 if n<=10 else 2 if n<=20 else 3]
    dispatch=.19 if n<=5 else .17 if n<=10 else .15 if n<=20 else .14
    flight=.8 if n<=5 else .95 if n<=10 else 1.05 if n<=20 else 1.15
    # Declared conservative pacing budget before any solver runs; no outcome-based tuning.
    deadline=math.ceil(beads*dispatch + teams*.75 + len(armors)*cooldown*.60 + 2*(a.w+a.h)/14 + (12 if n<=5 else 8))
    return {'schema_version':1,'level_id':f'campaign-{n:02}','level_number':n,'production_level_number':None,'campaign_draft_number':n,'content_version':'campaign-draft-1.0','content_kind':'authoring_draft','seed':2026102100+n,'pattern_name':name,'objective':goal,'width':a.w,'height':a.h,'palette':PALETTE,'grid':grid,'initial_color_counts':counts,'columns':columns,'armors':armors,'dragon':{'initial_position':0.0,'route_length':float(deadline),'speed_units_sec':1.0,'knockback_distance':.55 if n<=10 else .4,'max_knockback_distance':.55 if n<=10 else .4},'parameters':{'dispatch_interval_sec':dispatch,'transport_speed_cells_sec':14.0,'transport_min_leg_sec':.55,'pickup_pause_sec':.16,'max_inflight_ants':20 if n<=10 else 24,'cannon_cooldown_sec':cooldown,'projectile_flight_sec':flight},'tools':[{'id':x,'unlock_level':unlock,'uses_per_level':1} for x,unlock in [('extra_slot',3),('shuffle',6),('recall',9),('scout',16)]],'author_notes':{'motif':name,'progression_band':'01–05 exposed foundations' if n<=5 else '06–10 order and stock' if n<=10 else '11–20 layers and split quotas' if n<=20 else '21–30 combined planning','teaching_goal':goal,'queue_intent':'First-front color order '+','.join(PALETTE[s] for s in active)+('. Introductory colors use dedicated lanes.' if n<=5 else '. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5.')+' Team quotas vary independently of armor slices.','armor_intent':'Alternate forward/reverse cycles of '+','.join(PALETTE[s] for s in armor_order)+f'; {armor_parts} independently sized segment(s) per present color.','time_budget_policy':'Predeclared budget = ceil(beads × dispatch + teams × 0.75 + armor segments × cooldown × 0.60 + twice width-plus-height / 14 + band grace). Measured final-hit tail and margin must be recorded after authoritative replay.','failure_boundary_cases':['Final hit and princess contact at exactly the same microsecond: victory.','Contact one microsecond before final hit: defeat; later hit cannot overturn.','Empty board and last delivery are not victory; final projectile must hit.'],'playtest_conclusion':'NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.'},'validation':{'status':'UNVERIFIED','human_playtest':'NOT_RUN','visual_acceptance':'NOT_RUN','production_eligible':False}}

def main():
    p=argparse.ArgumentParser(); p.add_argument('--through',type=int,default=30); args=p.parse_args(); OUT.mkdir(parents=True,exist_ok=True)
    for n,spec in enumerate(SPECS[:args.through],1):
        level=build(n,spec); path=OUT/f'campaign-{n:02}.json'; path.write_text(json.dumps(level,indent=2,ensure_ascii=False)+'\n'); print(f'{level["level_id"]}: {level["pattern_name"]}, {sum(level["initial_color_counts"].values())} beads, {sum(len(c["teams"]) for c in level["columns"])} teams, {len(level["armors"])} armor segments, predeclared contact {level["dragon"]["route_length"]:g}s')
if __name__=='__main__': main()
