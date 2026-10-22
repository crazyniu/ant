#!/usr/bin/env python3
"""Compose approved/current card rows from current nodes. Never Godot/GL output.
Raw nodes and images are local evidence, not committed snapshots.
"""
from pathlib import Path
import argparse
from PIL import Image, ImageDraw, ImageFont
from render_first_level_offline import compose

ROOT = Path(__file__).resolve().parents[1]
FONT = str(ROOT / 'assets/fonts/Title.ttf')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--nodes-dir', type=Path, required=True)
    parser.add_argument('--output-dir', type=Path)
    args = parser.parse_args()
    output = args.output_dir or args.nodes_dir
    output.mkdir(parents=True, exist_ok=True)
    after, _, omitted = compose(args.nodes_dir / 'nodes-initial.json')
    reference = Image.open(ROOT / 'reports/first-level/approved-battle.jpeg')
    canvas = Image.new('RGB', (940, 610), '#e4d5b7')
    draw = ImageDraw.Draw(canvas)
    title = ImageFont.truetype(FONT, 24)
    label = ImageFont.truetype(FONT, 20)
    note = ImageFont.truetype(FONT, 17)
    draw.text((22, 16), 'FULL-ANT CARD COMPARISON / OFFLINE ONLY / NOT GODOT OR GL', font=title, fill='#382719')
    panels = [
        ('APPROVED ART: complete ants; four old cards / 20/30 are NOT current rules', reference.crop((50, 1242, 860, 1400))),
        ('CURRENT CANDIDATE: five colors / complete ants / same hit areas and counts', after.crop((62, 1342, 878, 1518))),
    ]
    for i, (text, image) in enumerate(panels):
        top = 66 + i * 225
        draw.text((25, top), text, font=label, fill='#382719')
        image = image.convert('RGBA')
        width = 816
        height = round(image.height * width / image.width)
        image = image.resize((width, height), Image.Resampling.LANCZOS)
        canvas.paste(image, (62, top + 35), image)
    draw.text((22, 535), 'Red/yellow dimming is the real blocked state. It is not removed for this comparison.', font=note, fill='#382719')
    draw.text((22, 560), 'CPU tint/filter/text approximation. Frame material and exact ant details remain open.', font=note, fill='#382719')
    draw.text((22, 585), 'Original complete abdomen/legs restored as a candidate, not pixel-identical extraction.', font=note, fill='#382719')
    canvas.save(output / 'cards-reference-current.png')

    states = Image.new('RGB', (940, 980), '#e4d5b7')
    d = ImageDraw.Draw(states)
    d.text((22, 15), 'LIVE-STATE NODE COMPOSITION / NOT GODOT OR GL', font=title, fill='#382719')
    for i, state in enumerate(['one-reserved', 'capacity-full', 'after-first-pickup', 'paused']):
        page, _, _ = compose(args.nodes_dir / f'nodes-{state}.json')
        d.text((25, 63 + i * 215), state.upper(), font=label, fill='#382719')
        crop = page.crop((62, 1342, 878, 1518))
        states.paste(crop, (62, 93 + i * 215), crop)
    d.text((22, 930), 'Counts include reservations until actual pickup. Not native input or GL acceptance.', font=note, fill='#382719')
    d.text((22, 955), 'CPU tint/text approximation; barrier/clock/check icons are omitted in this compositor.', font=note, fill='#382719')
    states.save(output / 'cards-live-state-offline.png')
    print({'not_godot_render': True, 'omitted_custom_icons': omitted, 'output': str(output)})


if __name__ == '__main__':
    main()
