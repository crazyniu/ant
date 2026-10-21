"""Verify capture_audio_mix.gd's actual Master PCM, never speaker listening."""
from pathlib import Path
import hashlib
import json
import math
import sys
import wave

import numpy as np
from scipy.signal import resample_poly

root = Path(sys.argv[1])
manifest = json.loads((root / "capture-manifest.json").read_text())
rows = {}
failures = []

def check(ok, message):
    if not ok:
        failures.append(message)

def db(value):
    return round(20 * math.log10(value), 3) if value else None

for segment in manifest["segments"]:
    path = root / Path(segment["file"]).name
    with wave.open(str(path)) as wav:
        check(wav.getsampwidth() == 2 and wav.getnchannels() == 2, f"Stereo PCM16: {path.name}")
        samples = np.frombuffer(wav.readframes(wav.getnframes()), dtype="<i2").reshape(-1, 2)
        rate = wav.getframerate()
    floats = samples.astype(np.float64) / 32768.0
    peak = float(np.max(np.abs(floats)))
    rms = float(np.sqrt(np.mean(floats ** 2)))
    true_peak = float(np.max(np.abs(resample_poly(floats, 4, 1, axis=0))))
    clipped = int(np.count_nonzero((samples == 32767) | (samples == -32768)))
    rows[segment["name"]] = {
        "file": path.name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "seconds": len(samples) / rate, "sample_rate": rate,
        "peak_dbfs": db(peak), "rms_dbfs": db(rms),
        "estimated_4x_true_peak_dbfs": db(true_peak),
        "clipped_samples": clipped, "exactly_silent": peak == 0,
        "sfx_started": segment["sfx_started"],
    }
    check(clipped == 0 and true_peak < 1.0, f"No sample/intersample clipping: {path.name}")
    check(len(samples) > rate * .8, f"Capture is nonempty: {path.name}")
for name in ["zero_music", "explicit_mute", "background_silence"]:
    check(rows[name]["exactly_silent"], f"Silence remains exact: {name}")
for name in ["before_bgm_70", "after_bgm_70", "modal_bgm_70", "settings_bgm_70"]:
    check(not rows[name]["exactly_silent"] and rows[name]["sfx_started"] == 0, f"BGM-only evidence: {name}")
normal = rows["after_bgm_70"]["rms_dbfs"]
baseline = rows["before_bgm_70"]["rms_dbfs"]
duck = rows["modal_bgm_70"]["rms_dbfs"]
settings = rows["settings_bgm_70"]["rms_dbfs"]
check(4.0 < normal - baseline < 6.1, "Calibrated BGM is materially louder at identical 70% setting")
check(2.5 < normal - duck < 5.0, "Modal BGM remains present at reduced gain")
check(abs(normal - settings) < 1.0, "Settings restores normal BGM gain")
report = {
    "pass": not failures, "failures": failures, "segments": rows,
    "normal_bgm_improvement_db": round(normal - baseline, 3),
    "audio_driver": manifest["audio_driver"],
    "source_bgm_sha256": manifest["original_bgm_sha256"],
    "audio_service_sha256": manifest["audio_service_sha256"],
    "scope": "Actual Godot Master PCM, including BGM-only contrasts and saturated mix; 4x polyphase true-peak estimate. Not an output-device or subjective listening pass.",
    "human_listening": "NOT_RUN", "hardware_output": "NOT_RUN",
}
(root / "mix-validation.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2))
raise SystemExit(0 if report["pass"] else 1)
