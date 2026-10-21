#!/usr/bin/env python3
"""Reproducible, original Ant Rescue score and cues. No samples or MIDI inputs.
Requires Python 3 + NumPy; all sound sources are oscillators and seeded noise.
"""
from __future__ import annotations
import hashlib, json, math, wave
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parent
SR = 44100
BPM = 96
BEAT = 60 / BPM
RNG = np.random.default_rng(338372)
CATALOG = []

def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12)

def envelope(n, attack=0.012, release=0.08):
    e = np.ones(n)
    a, r = min(n, round(attack * SR)), min(n, round(release * SR))
    if a: e[:a] *= np.sin(np.linspace(0, np.pi / 2, a)) ** 2
    if r: e[-r:] *= np.sin(np.linspace(np.pi / 2, 0, r)) ** 2
    return e

def tone(note, duration, kind="harp"):
    n = round(duration * SR)
    t = np.arange(n) / SR
    f = hz(note)
    if kind == "harp":
        y = (np.sin(2*np.pi*f*t)*np.exp(-t*3.0) +
             .29*np.sin(2*np.pi*2*f*t)*np.exp(-t*5) +
             .12*np.sin(2*np.pi*3*f*t)*np.exp(-t*8))
        y *= envelope(n, .008, .09)
    elif kind == "bell":
        y = (np.sin(2*np.pi*f*t)*np.exp(-t*2.3) +
             .22*np.sin(2*np.pi*f*2.01*t)*np.exp(-t*4.2) +
             .08*np.sin(2*np.pi*f*3.99*t)*np.exp(-t*7))
        y *= envelope(n, .013, .12)
    elif kind == "flute":
        phase = 2*np.pi*f*t + .035*np.sin(2*np.pi*4.8*t)
        y = np.sin(phase) + .11*np.sin(2*phase) + .025*np.sin(3*phase)
        y *= envelope(n, .055, .15)
    elif kind == "pad":
        y = (.65*np.sin(2*np.pi*f*t) + .18*np.sin(2*np.pi*f*1.002*t) +
             .09*np.sin(2*np.pi*f*2*t))
        y *= envelope(n, .3, .4)
    elif kind == "bass":
        y = (np.sin(2*np.pi*f*t) + .2*np.sin(2*np.pi*f*2*t))*np.exp(-t*1.6)
        y *= envelope(n, .02, .14)
    elif kind == "wood":
        y = (np.sin(2*np.pi*f*t) + .33*np.sin(2*np.pi*f*1.51*t))*np.exp(-t*17)
        y *= envelope(n, .007, .04)
    else:
        raise ValueError(kind)
    return y

def add(buf, signal, seconds, gain=1, pan=0, loop=False):
    angle = (pan + 1) * np.pi / 4
    stereo = np.column_stack((signal*np.cos(angle), signal*np.sin(angle))) * gain
    start = round(seconds * SR)
    if loop:
        ids = (np.arange(len(signal)) + start) % len(buf)
        np.add.at(buf, ids, stereo)
    elif start < len(buf):
        count = min(len(signal), len(buf)-start)
        buf[start:start+count] += stereo[:count]

def space(buf, loop=False, wet=.12):
    out = buf.copy()
    for delay, scale in [(.071,.55),(.137,.38),(.223,.27),(.359,.16)]:
        k=round(delay*SR)
        if loop:
            echo=np.roll(buf[:,::-1], k, axis=0)
        else:
            echo=np.zeros_like(buf); echo[k:]=buf[:-k,::-1]
        out += echo * wet * scale
    return out

def write(name, buf, purpose, peak=.43, loop=False, notes=None):
    buf -= np.mean(buf,axis=0)
    buf *= peak / max(float(np.max(np.abs(buf))), 1e-9)
    if not loop:
        buf *= envelope(len(buf), .004, .035)[:,None]
    pcm = np.round(np.clip(buf, -1, 1)*32767).astype('<i2')
    path=ROOT/(name+".wav")
    with wave.open(str(path),'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(SR); f.writeframes(pcm.tobytes())
    normalized=pcm.astype(float)/32768
    CATALOG.append({
        "id":name,"path":"res://assets/audio/"+path.name,"purpose":purpose,
        "duration_seconds":len(buf)/SR,"sample_rate_hz":SR,"channels":2,"pcm_bits":16,
        "frames":len(buf),"loop":loop,"peak_dbfs":round(20*math.log10(max(np.max(np.abs(normalized)),1e-12)),3),
        "rms_dbfs":round(20*math.log10(max(np.sqrt(np.mean(normalized**2)),1e-12)),3),
        "boundary_step":round(float(np.max(np.abs(normalized[0]-normalized[-1]))),8),
        "sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"bytes":path.stat().st_size,
        "notes":notes or "Original oscillator/noise synthesis, soft onset and release, no external recordings."
    })

def score():
    # 16 bars in C major: I vi IV V | I vi ii V | IV I vi V | ii IV V I.
    # Every part is authored here; melody is not derived from a reference tune.
    progression=[(48,52,55),(45,48,52),(41,45,48),(43,47,50),
                 (48,52,55),(45,48,52),(50,53,57),(43,47,50),
                 (53,57,60),(48,52,55),(45,48,52),(43,47,50),
                 (50,53,57),(53,57,60),(43,47,50),(48,52,55)]
    melody=[[(0,76,1), (1.5,79,.5),(2,81,1),(3,79,.75)],
            [(0,76,1.5),(2,72,.5),(3,76,.75)],
            [(.5,77,1),(2,76,.5),(3,72,.75)],
            [(0,74,1),(1.5,71,.5),(2.5,74,.5),(3.25,79,.5)],
            [(0,76,.75),(1,79,.75),(2.25,84,1)],
            [(.25,81,.75),(1.5,79,.5),(2.5,76,1)],
            [(0,77,1),(1.5,81,.5),(2.5,79,.5),(3.25,77,.5)],
            [(0,74,1.5),(2,71,.75),(3.25,74,.5)],
            [(0,77,.75),(1,81,.75),(2.25,84,1)],
            [(.5,79,1),(2,76,1),(3.25,72,.5)],
            [(0,76,.75),(1,81,.75),(2.25,79,.5),(3.25,76,.5)],
            [(0,74,1.5),(2,79,.75),(3.25,77,.5)],
            [(0,77,1),(1.5,74,.5),(2.5,69,.75)],
            [(0,72,.75),(1,77,.75),(2.25,76,.5),(3,72,.75)],
            [(0,74,1),(1.5,71,.5),(2.5,67,1)],
            [(0,72,2),(2.75,76,.5),(3.5,79,.4)]]
    buf=np.zeros((round(16*4*BEAT*SR),2))
    for bar,chord in enumerate(progression):
        start=bar*4*BEAT
        for i,n in enumerate(chord):
            add(buf,tone(n+12,4*BEAT+.35,"pad"),start-.15,.034,(-.55,0,.55)[i],True)
        for step,index in enumerate([0,2,1,2,0,2,1,2]):
            add(buf,tone(chord[index]+12,.72,"harp"),start+step*.5*BEAT,.080 if step%2==0 else .062,-.40,True)
        for beat in (0,2):
            add(buf,tone(chord[0]-(12 if chord[0]>=48 else 0),1.2,"bass"),start+beat*BEAT,.13,0,True)
        for beat in (1,3):
            add(buf,tone(60,.17,"wood"),start+beat*BEAT,.025,.36,True)
        for onset,n,duration in melody[bar]:
            add(buf,tone(n,duration*BEAT+.09,"flute"),start+onset*BEAT,.068,.22,True)
        if bar in (0,4,8,12,15):
            add(buf,tone(chord[2]+24,1.3,"bell"),start,.047,.5,True)
    write("bgm_castle_garden",space(buf,True,.2),"16-bar castle garden score; harp, breathy melody, warm pad, bass, celesta and wooden pulse.",peak=.40,loop=True,
          notes="Original 16-bar C-major multi-voice composition at 96 BPM, 4/4, 40.000 seconds. Circular reverb tails cross the exact loop boundary; no fade-to-silence loop.")

def motif(name, notes, purpose, kind="bell", duration=None, gain=.43):
    end=max(at+length for at,n,length in notes)+.4
    buf=np.zeros((round((duration or end)*SR),2))
    for i,(at,n,length) in enumerate(notes):
        add(buf,tone(n,length,kind),at,1.0,(-.25 if i%2==0 else .25))
    write(name,space(buf,False,.2),purpose,peak=gain)

def effects():
    motif("ui_click",[(0,79,.11),(.018,84,.12)],"Soft wooden button confirmation.","wood",.22,.32)
    motif("dispatch",[(0,60,.3),(.08,67,.32),(.16,72,.35)],"Team dispatch; buoyant upward harp.","harp")
    motif("pickup",[(0,84,.18),(.035,88,.2)],"Single bead pickup; small glass seed.","bell",.40,.27)
    motif("return",[(0,76,.28),(.085,72,.35),(.17,79,.4)],"Carrier reaches nest and delivers inventory.","harp",gain=.34)
    buf=np.zeros((round(.65*SR),2));t=np.arange(round(.38*SR))/SR
    phase=2*np.pi*(115*t-75*(t*t)/(.38*2))
    puff=RNG.normal(0,1,len(t));puff=np.convolve(puff,np.ones(34)/34,mode='same')
    shot=(.55*np.sin(phase)*np.exp(-t*13)+puff*.7*np.exp(-t*17))*envelope(len(t),.009,.08)
    add(buf,shot,0,1,0);add(buf,tone(55,.25,"wood"),.01,.3,.1)
    write("cannon",space(buf),"Rounded toy cannon thump and air puff, without a harsh explosion.",peak=.46)
    motif("armor_hit",[(0,73,.25),(.025,80,.35)],"Armor hit; short softened metal/chime pair.","bell",gain=.37)
    motif("warning",[(0,67,.4),(.32,67,.4),(.65,72,.45)],"Readable gentle three-note route warning.","flute",gain=.38)
    motif("tool_plus",[(0,60,.4),(.1,64,.5),(.2,67,.55),(.3,72,.8)],"Extra Slot accepted/released; expanding major harp fan.","harp")
    motif("tool_shuffle",[(0,79,.3),(.07,72,.3),(.14,76,.3),(.21,67,.3),(.28,74,.3),(.35,79,.55)],"Shuffle accepted/released; tumbling toy notes.","harp")
    motif("tool_recall",[(0,84,.55),(.14,79,.55),(.28,76,.55),(.42,72,.65)],"Recall accepted/released; descending homeward chimes.","bell")
    motif("tool_hint",[(0,79,.8),(.18,84,1),(.36,88,1.2)],"Hint accepted/released; rising discovery sparkle.","bell",gain=.35)
    motif("win",[(0,72,.55),(.17,76,.55),(.34,79,.55),(.55,84,1.3),(.55,76,1.3),(.55,67,1.3)],"Victory fanfare; short resolving C-major celebration.","bell",gain=.45)
    motif("lose",[(0,72,.7),(.3,69,.7),(.6,65,1),(.6,60,1)],"Gentle failure cadence, not an alarm.","flute",gain=.36)
    motif("error",[(0,65,.3),(.18,62,.4)],"Soft unavailable/action-rejected cue, distinct from defeat.","wood",gain=.32)

if __name__ == '__main__':
    ROOT.mkdir(parents=True,exist_ok=True)
    score();effects()
    manifest={"schema_version":1,"project":"Ant Rescue / Game 2","generated_utc_date":"2026-10-21",
      "authoring":"Original algorithmic composition and sound design authored for this project by the assistant.",
      "third_party_recordings":[],"third_party_melody_inputs":[],"external_downloads":[],
      "license_status":"Original project-generated audio. No third-party asset-pack license applies. Use remains subject to the project owner's terms and applicable assistant service terms; this provenance record is not a legal warranty.",
      "source":"res://assets/audio/generate_audio.py","source_sha256":hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
      "reproduce":"python assets/audio/generate_audio.py (Python 3 + NumPy; deterministic seed 338372)",
      "human_listening_status":"NOT RUN","gameplay_event_integration":"NOT CLAIMED: current game is a formal UI fixture, not a simulation.","files":CATALOG}
    (ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(f'Generated {len(CATALOG)} original WAV assets, {sum(x["bytes"] for x in CATALOG):,} bytes.')
