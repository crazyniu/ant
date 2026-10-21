"""Reproducible authored P2 configurations, not a claim of a production level editor.
Each pattern is constructed independently; replays are recorded by test_rules.gd.
"""
from pathlib import Path
from collections import Counter
import json
ROOT = Path(__file__).resolve().parents[2]
PALETTE = {'R':'red','B':'blue','Y':'yellow','G':'green','P':'purple','W':'white'}
HEX = {'R':'ef665b','B':'58b8ed','Y':'ffd65c','G':'70bc67','P':'b28be0','W':'fff5de'}
TOOLS = [dict(id=name, unlock_level=unlock, uses_per_level=1) for name,unlock in [('extra_slot',3),('shuffle',6),('recall',9),('scout',16)]]

def quota_teams(counts, color_order, size=18):
    by_color = {}
    for color in color_order:
        n=counts[color]; parts=[]
        while n:
            amount=min(size,n)
            parts.append(dict(id=f'{color}-{len(parts)+1:02}',color=color,quota=amount)); n-=amount
        by_color[color]=parts
    return by_color

def make(level_id, title, grid, order, armor_order, params, dragon, objective):
    counts=Counter(PALETTE[c] for row in grid for c in row if c!='.')
    teams=quota_teams(counts,order)
    # Each color has one stable lane. The sixth color follows the earliest lane's
    # teams, intentionally making column order part of the puzzle.
    columns=[dict(id=f'column-{i+1}',teams=teams[color]) for i,color in enumerate(order[:5])]
    columns[0]['teams'] = columns[0]['teams'] + teams[order[5]]
    armors=[]
    # Two halves per color: excess stock is retained for a later same-color armor.
    portions={c:[(counts[c]+1)//2, counts[c]//2] for c in counts}
    for phase in range(2):
        for color in armor_order:
            amount=portions[color][phase]
            if amount:armors.append(dict(id=f'{level_id}-armor-{len(armors)+1:02}',color=color,demand=amount))
    config=dict(schema_version=1,content_version='p2.1',level_id=level_id,pattern_name=title,seed=20261021,
        content_kind='independent_validation_level',production_level_number=None,width=len(grid[0]),height=len(grid),grid=grid,palette=PALETTE,
        initial_color_counts=dict(counts),columns=columns,armors=armors,parameters=params,dragon=dragon,tools=TOOLS,
        objective=objective,thumbnail=f'res://reports/rules/{level_id}.svg',
        validation=dict(status='PENDING_REPLAY',human_playtest='NOT_RUN',visual_acceptance='NOT_RUN',no_tool_solution=[],
          click_interval_sec=0.75,deadline_sec=240, failure_boundary_cases=['contact before final hit','exact contact/hit tie','final pickup and delivery are not victory']))
    (ROOT/'data'/'levels'/f'{level_id}.json').write_text(json.dumps(config,indent=2,ensure_ascii=False)+'\n')
    svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{len(grid[0])*18}" height="{len(grid)*18}" viewBox="0 0 {len(grid[0])*18} {len(grid)*18}">', '<rect width="100%" height="100%" fill="#eed8b6"/>']
    for y,row in enumerate(grid):
        for x,c in enumerate(row):
            if c!='.':svg.append(f'<rect x="{x*18+1}" y="{y*18+1}" width="16" height="16" rx="4" fill="#{HEX[c]}"/>')
    svg.append('</svg>'); (ROOT/'reports'/'rules'/f'{level_id}.svg').write_text('\n'.join(svg))

# An original sunrise blossom on a blue pond, with transparent outside corners.
grid1=[
'.....YYYYYY.....',
'...YYYYWWYYYY...',
'..YYYWWWWWWYYY..',
'.YYYWWRRRRWWYYY.',
'YYYWWRRRRRRWWYYY',
'YYYWRRPPPRRWWYYY',
'YYYWRRPPPRRWWYYY',
'YYYWWRRRRRRWWYYY',
'.YYYWWRRRRWWYYY.',
'..YYYWWWWWWYYY..',
'...GGGYYGGGGG...',
'..GGGGGGGGGGGG..',
'.GGGGGGGGGGGGGG.',
'BBBBBBBBBBBBBBBB',
'BBBBBBBBBBBBBBBB',
'BBBBBBBBBBBBBBBB']
# A fortress's nested walls expose all sides but seal a purple inner courtyard.
grid2=[]
for y in range(16):
    row=''
    for x in range(16):
        d=min(x,y,15-x,15-y)
        row += ['W','R','G','Y','B','P','B','W'][d]
    grid2.append(row)
# An original tower-and-lantern silhouette, not a recolored version of either.
grid3=[
'....WW......WW....',
'...WWWW....WWWW...',
'...WPPW....WPPW...',
'...WPPWWWWWWPPW...',
'...WRRRRRRRRRRW...',
'...WRRYYYYYYRRW...',
'...WRRYYYYYYRRW...',
'...WGGYYYYYYGGW...',
'..WWGGGYYYYGGGWW..',
'.WWWGGGGYYGGGGWWW.',
'WWWWGGGGGGGGGGWWWW',
'BBBBBBBBBBBBBBBBBB',
'BBBBBBB....BBBBBBB',
'BBBBBB......BBBBBB']
base=dict(dispatch_interval_sec=0.12,transport_speed_cells_sec=14.0,transport_min_leg_sec=.55,pickup_pause_sec=.16,max_inflight_ants=30,cannon_cooldown_sec=2.4,projectile_flight_sec=0.85)
make('validation-01','Sunrise Blossom',grid1,['blue','yellow','white','red','green','purple'],['blue','yellow','white','red','green','purple'],base,dict(route_length=45.0,speed_units_sec=1.0,initial_position=0.0,knockback_distance=1.2,max_knockback_distance=1.2),'Base loop: front selection, five-slot dispatch, pickup, delivery, auto fire and final-hit victory.')
make('validation-02','Six-Wall Courtyard',grid2,['blue','white','red','green','yellow','purple'],['blue','white','red','green','yellow','purple'],dict(base,dispatch_interval_sec=0.11,max_inflight_ants=28),dict(route_length=55.0,speed_units_sec=1.0,initial_position=0.0,knockback_distance=1.0,max_knockback_distance=1.0),'Select hidden blue first. It must wait for exposed walls, then resume without another click; white and red accumulate before the first blue armor breaks.')
make('validation-03','Twin Lantern Bridge',grid3,['blue','white','red','green','yellow','purple'],['blue','white','red','green','yellow','purple'],dict(base,dispatch_interval_sec=0.13,cannon_cooldown_sec=6.0,projectile_flight_sec=1.35),dict(route_length=70.35,speed_units_sec=1.0,initial_position=0.0,knockback_distance=0.6,max_knockback_distance=0.6),'Tail budget: board clears before late cooldowns; last delivery and final fire are not victory. Princess timing includes final projectile flight.')
print('Authored 3 independent validation patterns.')
