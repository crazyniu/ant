#!/usr/bin/env python3
"""Card-only source/node comparison. Never represents Godot/GL output."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont
from render_first_level_offline import compose

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "reports/first-level/batch-3"
FONT = str(ROOT / "assets/fonts/Title.ttf")


def main():
    before_path = ROOT / "reports/first-level/batch-2/nodes-after-initial.json"
    # The old card actor was a non-drawing Control. Its disabled modulation was
    # absent from leaf-only batch-2 exports. Reconstruct only this known ancestor
    # from recorded visible blocked/collected icons and play.gd sync_view().
    inherited = {}
    for item in json.loads(before_path.read_text())["nodes"]:
        if item["name"].startswith("CandidateQueues/ColorState_") and item.get("kind") in ("barrier", "check"):
            color = item["name"].removeprefix("CandidateQueues/ColorState_")
            inherited[f"CandidateQueues/ColorAnt_{color}/"] = [.55, .55, .55, .72]
    before, _, _ = compose(before_path, inherited)
    after, _, omitted = compose(OUT / "nodes-initial.json")
    reference = Image.open(ROOT / "reports/first-level/approved-battle.jpeg")
    before.convert("RGB").save(OUT / "before-offline.png")
    after.convert("RGB").save(OUT / "after-offline.png")
    canvas = Image.new("RGB", (940, 850), "#e4d5b7")
    draw = ImageDraw.Draw(canvas)
    title = ImageFont.truetype(FONT, 24)
    label = ImageFont.truetype(FONT, 20)
    note = ImageFont.truetype(FONT, 17)
    draw.text((22, 16), "CARD ART COMPARISON / OFFLINE ONLY / NOT GODOT OR GL", font=title, fill="#382719")
    panels = [
        ("APPROVED ART: four legacy cards; 20/30 are NOT current rules", reference.crop((50, 1242, 860, 1400))),
        ("BEFORE: five live controls / old small side-facing carrier art", before.crop((62, 1342, 878, 1518))),
        ("CANDIDATE: same five controls and live counts / new portrait art", after.crop((62, 1342, 878, 1518))),
    ]
    for i, (text, image) in enumerate(panels):
        top = 66 + i * 237
        draw.text((25, top), text, font=label, fill="#382719")
        image = image.convert("RGBA")
        # Equal displayed row width. Source and candidate card counts intentionally differ.
        width = 816
        height = round(image.height * width / image.width)
        image = image.resize((width, height), Image.Resampling.LANCZOS)
        canvas.paste(image, (62, top + 35), image)
    draw.text((22, 789), "Actual node positions. CPU color tint/filtering/text approximation, not GPU pixels.", font=note, fill="#382719")
    draw.text((22, 817), "One press sends one ant. Capacity 4. Original hit/count rectangles unchanged.", font=note, fill="#382719")
    canvas.save(OUT / "cards-reference-before-after.png")

    states = Image.new("RGB", (940, 980), "#e4d5b7")
    d = ImageDraw.Draw(states)
    d.text((22, 15), "LIVE-STATE NODE COMPOSITION / NOT GODOT OR GL", font=title, fill="#382719")
    for i, state in enumerate(["one-reserved", "capacity-full", "after-first-pickup", "paused"]):
        page, _, _ = compose(OUT / f"nodes-{state}.json")
        d.text((25, 63 + i * 215), state.upper(), font=label, fill="#382719")
        crop = page.crop((62, 1342, 878, 1518))
        states.paste(crop, (62, 93 + i * 215), crop)
    d.text((22, 930), "Counts include reservations until actual pickup. Not native input or GL acceptance.", font=note, fill="#382719")
    d.text((22, 955), "CPU tint/text approximation; barrier/clock/check icons are omitted in this compositor.", font=note, fill="#382719")
    states.save(OUT / "cards-live-state-offline.png")
    print({"not_godot_render": True, "omitted_custom_icons": omitted, "output": str(OUT)})


if __name__ == "__main__":
    main()
