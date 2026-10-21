#!/usr/bin/env python3
"""Independent numerical validation; explicitly not a human listening test."""
import hashlib, json, math, subprocess, wave
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parent
manifest=json.loads((ROOT/'manifest.json').read_text())
failures=[]; checks=0

def check(ok, message):
    global checks
    checks+=1
    if not ok: failures.append(message)

check(hashlib.sha256((ROOT/'generate_audio.py').read_bytes()).hexdigest()==manifest['source_sha256'],'generator hash')
check(len(manifest['files'])==15,'15 file catalog')
hashes=[]; metrics=[]
for item in manifest['files']:
    path=ROOT/Path(item['path']).name
    check(path.is_file(), f'{item["id"]}: source exists')
    if not path.is_file():
        continue
    digest=hashlib.sha256(path.read_bytes()).hexdigest();hashes.append(digest)
    check(digest==item['sha256'],f'{item["id"]}: source hash')
    check(path.stat().st_size==item['bytes'],f'{item["id"]}: exact file size')
    if path.suffix == '.ogg':
        # Decode to float so out-of-range samples are visible, not hidden by PCM16 clipping.
        probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','a:0','-show_streams','-show_format','-of','json',str(path)]))
        stream=probe['streams'][0]
        check(stream['codec_name']=='vorbis' and probe['format']['format_name']=='ogg','BGM is an Ogg Vorbis stream')
        check(int(stream['sample_rate'])==44100 and stream['channels']==2,'BGM remains stereo 44.1kHz')
        check(abs(float(stream['duration'])-40.0)<1/44100,'BGM encoded duration is exactly 40 seconds')
        check(int(stream['bit_rate'])==160000,'BGM nominal encoding target remains 160 kbps')
        check(path.stat().st_size<1000000,'BGM compact runtime source is below 1 MB')
        raw=subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-f','f32le','-acodec','pcm_f32le','-'])
        values=np.frombuffer(raw,dtype='<f4').reshape(-1,2).astype(float)
        check(len(values)==item['frames'],'BGM decoded frame count matches the original master')
    else:
        with wave.open(str(path),'rb') as w:
            check(w.getnchannels()==2 and w.getsampwidth()==2 and w.getframerate()==44100,f'{item["id"]}: stereo PCM16 44.1kHz')
            check(w.getnframes()==item['frames'],f'{item["id"]}: exact frame count')
            values=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').reshape(-1,2).astype(float)/32768
    check(np.all(np.isfinite(values)) and np.max(np.abs(values))<1.0,f'{item["id"]}: finite decoded samples and no digital clipping')
    peak=float(np.max(np.abs(values)));rms=float(np.sqrt(np.mean(values**2)));dc=float(np.max(np.abs(np.mean(values,axis=0))))
    boundary=float(np.max(np.abs(values[0]-values[-1])))
    check(.01<peak<.6,f'{item["id"]}: non-silent, bounded sample peak')
    check(.001<rms<.25,f'{item["id"]}: useful RMS, not overloaded')
    check(dc<.001,f'{item["id"]}: negligible DC')
    check(np.max(np.abs(values[:,0]-values[:,1]))>.0001,f'{item["id"]}: genuine stereo content')
    if item['loop']:
        check(len(values)==40*44100,'full 40-second score')
        check(boundary<.015,'loop seam sample step below 0.015 FS')
        # The seam must be comparable to ordinary adjacent-sample transitions.
        p99=float(np.percentile(np.max(np.abs(np.diff(values,axis=0)),axis=1),99))
        check(boundary<max(.003,p99*1.5),'loop seam does not introduce abnormal discontinuity')
        windows=values.reshape(16,-1,2)
        bar_rms=np.sqrt(np.mean(windows**2,axis=(1,2)))
        check(np.min(bar_rms)>.02,'all 16 score bars contain sustained multi-part audio')
        check(np.std(bar_rms)>.001,'score has non-identical bar dynamics')
    else:
        check(np.max(np.abs(values[:30]))<.03,f'{item["id"]}: soft initial attack')
        check(np.max(np.abs(values[-30:]))<.003,f'{item["id"]}: released file ending')
    metrics.append({'id':item['id'],'format':path.suffix[1:],'seconds':len(values)/44100,'peak_dbfs':round(20*math.log10(peak),2),'rms_dbfs':round(20*math.log10(rms),2),'dc':round(dc,9),'seam_step':round(boundary,9)})
check(len(set(hashes))==15,'all score and cue files are distinct')
check(len(list(ROOT.glob('*.ogg')))==1 and len(list(ROOT.glob('*.wav')))==14,'one compact OGG score and all 14 WAV cues; no redundant PCM BGM')
report={'pass':not failures,'checks':checks,'failures':failures,'files':metrics,'scope':'Independent file/hash/format/non-silence/float-decode clipping/headroom/DC/stereo/attack/release/loop-seam checks; Vorbis full duration and frame preservation.','human_listening':'NOT RUN','hardware_audio':'NOT RUN','gameplay_integration':'NOT CLAIMED'}
(ROOT/'file-validation-report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
raise SystemExit(1 if failures else 0)
