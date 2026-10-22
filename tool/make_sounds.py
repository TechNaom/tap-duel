"""Generate the game's sound effects as small WAV files (stdlib only).

Run from the repo root:  python tool/make_sounds.py
Writes to assets/sounds/.
"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def tone(freq, dur, vol=0.6, decay=8.0, freq_end=None, harmonics=(1.0,)):
    """A sine tone with an exponential fade; optional pitch slide and overtones."""
    n = int(RATE * dur)
    samples = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = freq if freq_end is None else freq + (freq_end - freq) * (i / n)
        phase += 2 * math.pi * f / RATE
        attack = min(1.0, i / (RATE * 0.004))  # 4 ms fade-in avoids clicks
        env = attack * math.exp(-decay * t)
        s = sum(h * math.sin(phase * (k + 1)) for k, h in enumerate(harmonics))
        samples.append(vol * env * s / sum(harmonics))
    return samples


def mix(*tracks):
    """Overlay tracks given as (start_seconds, samples)."""
    length = max(int(start * RATE) + len(s) for start, s in tracks)
    out = [0.0] * length
    for start, s in tracks:
        offset = int(start * RATE)
        for i, v in enumerate(s):
            out[offset + i] += v
    return out


def save(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1.0, max(abs(v) for v in samples))
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v / peak * 32000)) for v in samples))
    print(f"wrote {name} ({len(samples) / RATE:.2f}s)")


# Short bright "pop" per side, pitched differently so players hear their own taps.
save("tap_red.wav", tone(880, 0.07, decay=45, freq_end=1320, harmonics=(1, 0.3)))
save("tap_blue.wav", tone(660, 0.07, decay=45, freq_end=990, harmonics=(1, 0.3)))

# Low falling buzz for the -1.
save("minus.wav", tone(220, 0.22, vol=0.7, decay=10, freq_end=110, harmonics=(1, 0.6, 0.4, 0.3)))

# Rising three-note chime for 250 / 500 / 750.
save("milestone.wav", mix(
    (0.00, tone(784, 0.25, decay=9, harmonics=(1, 0.4))),
    (0.08, tone(988, 0.25, decay=9, harmonics=(1, 0.4))),
    (0.16, tone(1319, 0.45, decay=6, harmonics=(1, 0.4))),
))

# Victory fanfare: C-E-G arpeggio into a held major chord.
notes = [(0.00, 523), (0.14, 659), (0.28, 784)]
chord = [(0.45, f) for f in (523, 659, 784, 1047)]
save("win.wav", mix(*[
    (start, tone(f, 0.35 if start < 0.4 else 1.3, vol=0.5, decay=3 if start < 0.4 else 1.6,
                 harmonics=(1, 0.5, 0.25)))
    for start, f in notes + chord
]))
