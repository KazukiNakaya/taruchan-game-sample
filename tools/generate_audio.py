"""仮の効果音・BGMを生成する(Python標準ライブラリのみ)。

使い方: プロジェクトのルートで `python tools/generate_audio.py`
出力: audio/sfx/*.wav, audio/ambient/*.wav, audio/bgm/*.wav
本番素材ができたら、同じファイル名で差し替える(コードは名前で読み込む)。
足音(audio/footsteps/)は別に生成済み。
"""
import math
import os
import random
import struct
import wave

SR = 22050
random.seed(7)


def write(path, samples, peak=0.9):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    m = max(abs(x) for x in samples) or 1.0
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x / m * peak)) * 32767)) for x in samples))


def noise(n):
    return [random.uniform(-1, 1) for _ in range(n)]


def lowpass(xs, a):
    y = 0.0
    out = []
    for x in xs:
        y += a * (x - y)
        out.append(y)
    return out


def bandpass(xs, lo, hi):
    return lowpass([a - b for a, b in zip(xs, lowpass(xs, lo))], hi)


def env(n, attack, decay):
    return [min(1.0, i / (attack * SR + 1)) * math.exp(-i / (decay * SR)) for i in range(n)]


def silence(sec):
    return [0.0] * int(sec * SR)


def mix_at(dst, src, start):
    for i, x in enumerate(src):
        j = start + i
        if j < len(dst):
            dst[j] += x


def bell(freq, dur, decay=0.35, gain=1.0):
    n = int(dur * SR)
    e = env(n, 0.005, decay)
    return [gain * e[i] * (math.sin(2 * math.pi * freq * i / SR) + 0.3 * math.sin(4 * math.pi * freq * i / SR)) for i in range(n)]


# ---- クンクン(短い息を2回) ----
for v in range(3):
    out = silence(0.0)
    for k in range(2):
        n = int((0.07 + random.uniform(0, 0.02)) * SR)
        burst = bandpass(noise(n), 0.1, 0.5)
        e = env(n, 0.012, 0.03)
        out += [b * x for b, x in zip(burst, e)] + silence(0.06)
    write(f"audio/sfx/sniff_{v + 1}.wav", out)

# ---- 掘る(土を掻く) ----
for v in range(2):
    out = []
    for k in range(4):
        n = int(0.07 * SR)
        burst = lowpass(noise(n), 0.25)
        e = env(n, 0.006, 0.03)
        out += [b * x for b, x in zip(burst, e)] + silence(0.03 + 0.01 * v)
    write(f"audio/sfx/dig_{v + 1}.wav", out)

# ---- 発見ジングル(C E G C) ----
notes = [523.25, 659.25, 783.99, 1046.5]
out = silence(1.4)
for i, f in enumerate(notes):
    mix_at(out, bell(f, 0.9, 0.3, 0.8), int(i * 0.16 * SR))
write("audio/sfx/discover.wav", out)

# ---- ゴール(ゆったりしたアルペジオ) ----
notes = [392.0, 523.25, 659.25, 783.99, 1046.5]
out = silence(2.8)
for i, f in enumerate(notes):
    mix_at(out, bell(f, 1.6, 0.6, 0.8), int(i * 0.28 * SR))
write("audio/sfx/goal.wav", out)

# ---- ジャンプ/着地 ----
n = int(0.14 * SR)
e = env(n, 0.01, 0.06)
write("audio/sfx/jump.wav", [e[i] * math.sin(2 * math.pi * (300 + 2200 * i / SR) * i / SR) * 0.6 for i in range(n)])
n = int(0.14 * SR)
e = env(n, 0.004, 0.035)
thump = lowpass(noise(n), 0.15)
write("audio/sfx/land.wav", [e[i] * (math.sin(2 * math.pi * 85 * i / SR) * 0.8 + thump[i] * 0.7) for i in range(n)])

# ---- UI ----
n = int(0.05 * SR)
e = env(n, 0.003, 0.02)
write("audio/sfx/ui_click.wav", [e[i] * math.sin(2 * math.pi * 900 * i / SR) for i in range(n)])
out = bell(660, 0.25, 0.08, 0.8)
mix_at(out, bell(880, 0.25, 0.08, 0.8), int(0.08 * SR))
write("audio/sfx/menu_open.wav", out)
out = bell(880, 0.25, 0.08, 0.8)
mix_at(out, bell(660, 0.25, 0.08, 0.8), int(0.08 * SR))
write("audio/sfx/menu_close.wav", out)

# ---- 鳥の声 ----
def chirp(f0, f1, dur, vib=30.0):
    n = int(dur * SR)
    e = [math.sin(math.pi * i / n) ** 1.5 for i in range(n)]
    out = []
    ph = 0.0
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * t + 120 * math.sin(2 * math.pi * vib * i / SR)
        ph += 2 * math.pi * f / SR
        out.append(e[i] * math.sin(ph))
    return out


for v in range(4):
    out = silence(0.0)
    count = random.randint(2, 5)
    base = random.uniform(2400, 4200)
    for k in range(count):
        d = random.uniform(0.06, 0.13)
        up = random.random() < 0.6
        f0 = base * random.uniform(0.9, 1.1)
        f1 = f0 * (1.35 if up else 0.7)
        out += chirp(f0, f1, d, random.uniform(20, 60)) + silence(random.uniform(0.04, 0.1))
    write(f"audio/ambient/bird_{v + 1}.wav", out, 0.6)

# ---- BGM(やわらかいパッド+まばらなベル。ループ前提で、余韻は先頭へ回り込ませる) ----
chords = [
    [130.81, 164.81, 196.0, 246.94],   # Cmaj7
    [110.0, 130.81, 164.81, 196.0],    # Am7
    [87.31, 110.0, 130.81, 164.81],    # Fmaj7
    [98.0, 123.47, 146.83, 164.81],    # G6
]
SEG = 6.0
TOTAL = int(SEG * len(chords) * SR)
out = [0.0] * TOTAL


def add_wrap(dst, src, start):
    for i, x in enumerate(src):
        dst[(start + i) % len(dst)] += x


for ci, chord in enumerate(chords):
    for f in chord:
        n = int((SEG + 2.5) * SR)
        seg = []
        for i in range(n):
            t = i / SR
            a = min(1.0, t / 1.4)
            r = 1.0 if t < SEG else max(0.0, 1.0 - (t - SEG) / 2.5)
            s = math.sin(2 * math.pi * f * t) + 0.35 * math.sin(4 * math.pi * f * t + 0.5)
            seg.append(0.12 * a * r * s)
        add_wrap(out, seg, int(ci * SEG * SR))
scale = [523.25, 587.33, 659.25, 783.99, 880.0]
t = 1.0
while t < SEG * len(chords) - 1.0:
    add_wrap(out, bell(random.choice(scale), 2.2, 0.7, 0.09), int(t * SR))
    t += random.uniform(1.6, 3.2)
write("audio/bgm/forest_loop.wav", out, 0.5)
# 後から追加した音は末尾で作る(前の音の乱数の並びを変えないため)
# ---- 足音: 水(小川の浅瀬。ちゃぷっ) ----
for v in range(3):
    n = int(0.22 * SR)
    e = env(n, 0.004, 0.05)
    splash = bandpass(noise(n), 0.05, 0.35)
    bubble = [math.sin(2 * math.pi * (500 + 900 * (i / n) + 150 * v) * i / SR) * math.exp(-i / (0.03 * SR)) for i in range(n)]
    write(f"audio/footsteps/water_{v + 1}.wav", [e[i] * (splash[i] * 0.9 + bubble[i] * 0.5) for i in range(n)])

print("done")
