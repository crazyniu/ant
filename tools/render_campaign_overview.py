#!/usr/bin/env python3
"""Assemble current engine-exported bead thumbnails for author inspection.
Not a runtime screenshot and not human visual acceptance. Requires Pillow.
"""
from pathlib import Path
import hashlib, json
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'data/campaign-drafts'; REPORT=ROOT/'reports/campaign'
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
def font(size):
    try: return ImageFont.truetype(FONT,size)
    except OSError: return ImageFont.load_default()

def sheet(numbers, output, columns=5):
    cell_w,cell_h=270,300
    rows=(len(numbers)+columns-1)//columns
    canvas=Image.new('RGB',(columns*cell_w,rows*cell_h+90),'#f8f0dc'); d=ImageDraw.Draw(canvas)
    d.text((24,16),'ANT RESCUE · ORIGINAL CAMPAIGN DRAFTS',font=font(24),fill='#3f352d')
    d.text((24,51),'Authoring thumbnails · timed no-tool replays verified · human / visual acceptance NOT RUN',font=font(15),fill='#776953')
    for slot,n in enumerate(numbers):
        data=json.loads((DATA/f'campaign-{n:02}.json').read_text())
        x=(slot%columns)*cell_w; y=(slot//columns)*cell_h+90
        thumb=Image.open(DATA/data['thumbnail']).convert('RGB'); thumb.thumbnail((244,230),Image.Resampling.LANCZOS)
        canvas.paste(thumb,(x+(cell_w-thumb.width)//2,y+30+(230-thumb.height)//2))
        d.text((x+14,y+7),f'{n:02}  {data["pattern_name"]}',font=font(15),fill='#3f352d')
        counts=data['initial_color_counts']; v=data['validation']; colors=sum(bool(c) for c in counts.values())
        d.text((x+14,y+264),f'{sum(counts.values())} beads · {colors} colors · hit {v["terminal_time_us"]/1e6:.1f}s',font=font(13),fill='#776953')
    REPORT.mkdir(parents=True,exist_ok=True); canvas.save(REPORT/output,optimize=True)

sheet(list(range(1,31)),'campaign-overview.png')
manifest_path=REPORT/'manifest.json'
manifest=json.loads(manifest_path.read_text())
for entry in manifest['levels']:
    level=DATA/(entry['level_id']+'.json')
    entry['json_sha256']=hashlib.sha256(level.read_bytes()).hexdigest()
    entry['thumbnail_sha256']=hashlib.sha256((DATA/entry['thumbnail']).read_bytes()).hexdigest()
manifest['inspection_sheet']='res://reports/campaign/campaign-overview.png'
manifest_path.write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
print('Wrote current complete inspection sheet and artifact checksums')
