import struct, math, wave, random, os

SAMPLE_RATE = 22050
SFX_DIR = os.path.join(os.path.dirname(__file__), "assets", "audio", "sfx")
os.makedirs(SFX_DIR, exist_ok=True)

def generate_wav(filename, sample_rate, duration, samples_func):
    n_samples = int(sample_rate * duration)
    samples = [samples_func(i, sample_rate, n_samples) for i in range(n_samples)]
    samples = [max(-1.0, min(1.0, s)) for s in samples]
    int_samples = [int(s * 32767) for s in samples]
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        f.writeframes(struct.pack('<' + 'h' * len(int_samples), *int_samples))
    print(f"  Created: {os.path.basename(filename)} ({duration:.2f}s, {os.path.getsize(filename)} bytes)")

def square(phase):
    return 1.0 if (phase % 1.0) < 0.5 else -1.0

def triangle(phase):
    p = phase % 1.0
    if p < 0.25: return p * 4.0
    elif p < 0.75: return 2.0 - p * 4.0
    else: return p * 4.0 - 4.0

def noise():
    return random.uniform(-1, 1)

def envelope(t, attack=0.01, decay=0.05, sustain_level=0.7, release_start=0.8, total=1.0):
    """ADSR envelope, t is normalized 0-1"""
    if t < attack:
        return t / attack
    elif t < attack + decay:
        return 1.0 - (1.0 - sustain_level) * ((t - attack) / decay)
    elif t < release_start:
        return sustain_level
    else:
        return sustain_level * (1.0 - (t - release_start) / (1.0 - release_start))

# ---- JUMP: upward pitch sweep ----
def jump_func(i, sr, n):
    t = i / n
    freq = 200 + 800 * t  # sweep 200 -> 1000 Hz
    env = 1.0 - t  # fade out
    phase = i * freq / sr
    return square(phase) * env * 0.5

# ---- LAND: thud ----
def land_func(i, sr, n):
    t = i / n
    freq = 100 * (1.0 - t * 0.5)  # low freq dropping
    env = (1.0 - t) ** 3
    phase = i * freq / sr
    return (square(phase) * 0.3 + noise() * 0.4) * env

# ---- STEP: soft click ----
def step_func(i, sr, n):
    t = i / n
    env = (1.0 - t) ** 5
    freq = 300
    phase = i * freq / sr
    return (triangle(phase) * 0.3 + noise() * 0.15) * env

# ---- COLLECT: bright ascending arpeggio (coin-like) ----
def collect_func(i, sr, n):
    t = i / n
    # 4-note arpeggio: C5 E5 G5 C6
    notes = [523.25, 659.25, 783.99, 1046.50]
    note_idx = min(int(t * len(notes)), len(notes) - 1)
    freq = notes[note_idx]
    local_t = (t * len(notes)) - note_idx
    env = max(0, 1.0 - local_t * 1.5) * (1.0 - t * 0.3)
    phase = i * freq / sr
    return (square(phase) * 0.3 + triangle(phase * 2.0) * 0.2) * env

# ---- HURT: descending buzz ----
def hurt_func(i, sr, n):
    t = i / n
    freq = 400 - 300 * t  # descend
    env = (1.0 - t) ** 1.5
    phase = i * freq / sr
    # harsh buzz = square with some noise
    return (square(phase) * 0.4 + square(phase * 0.5) * 0.2 + noise() * 0.1) * env

# ---- THROW: whoosh ----
def throw_func(i, sr, n):
    t = i / n
    # noise filtered with envelope
    env = math.sin(t * math.pi)  # bell curve
    freq = 200 + 600 * t
    phase = i * freq / sr
    return (noise() * 0.5 + triangle(phase) * 0.15) * env

# ---- HIT ENEMY: impact with sparkle ----
def hit_enemy_func(i, sr, n):
    t = i / n
    if t < 0.3:
        # impact
        env = (1.0 - t / 0.3) ** 2
        freq = 150
        phase = i * freq / sr
        return (square(phase) * 0.4 + noise() * 0.3) * env
    else:
        # sparkle
        local_t = (t - 0.3) / 0.7
        env = (1.0 - local_t) ** 2
        freq = 1200 + 400 * math.sin(local_t * 20)
        phase = i * freq / sr
        return triangle(phase) * env * 0.4

# ---- DOOR: sliding sound ----
def door_func(i, sr, n):
    t = i / n
    env = math.sin(t * math.pi) * 0.8
    freq = 80 + 40 * math.sin(t * 8 * math.pi)
    phase = i * freq / sr
    return (noise() * 0.3 + square(phase) * 0.2) * env

# ---- TRAIN AMBIENT: rhythmic chugging ----
def train_ambient_func(i, sr, n):
    t = i / sr  # time in seconds
    # Chug pattern: repeating every ~0.4 seconds
    chug_period = 0.4
    chug_phase = (t % chug_period) / chug_period
    chug_env = max(0, 1.0 - chug_phase * 3) if chug_phase < 0.33 else 0
    # Rail click every ~1.2 seconds
    rail_period = 1.2
    rail_phase = (t % rail_period) / rail_period
    rail_click = max(0, 1.0 - rail_phase * 20) if rail_phase < 0.05 else 0
    # Steam hiss
    hiss = noise() * 0.08
    freq = 60
    phase = i * freq / sr
    return (square(phase) * chug_env * 0.3 + noise() * chug_env * 0.2 + rail_click * noise() * 0.5 + hiss)

# ---- MENU SELECT: short bright blip ----
def menu_select_func(i, sr, n):
    t = i / n
    env = (1.0 - t) ** 3
    freq = 880
    phase = i * freq / sr
    return square(phase) * env * 0.4

# ---- MENU CONFIRM: two-tone confirmation ----
def menu_confirm_func(i, sr, n):
    t = i / n
    if t < 0.5:
        freq = 660
    else:
        freq = 880
    env = (1.0 - ((t * 2) % 1.0)) if t < 0.5 else (1.0 - (t - 0.5) * 2)
    env = max(0, env) ** 1.5
    phase = i * freq / sr
    return (square(phase) * 0.3 + triangle(phase) * 0.2) * env

# ---- GAME OVER: sad descending melody ----
def game_over_func(i, sr, n):
    t = i / n
    # Descending minor notes: D5 Bb4 G4 D4
    notes = [587.33, 466.16, 392.00, 293.66]
    dur_per_note = 1.0 / len(notes)
    note_idx = min(int(t / dur_per_note), len(notes) - 1)
    freq = notes[note_idx]
    local_t = (t - note_idx * dur_per_note) / dur_per_note
    env = max(0, 1.0 - local_t * 0.8) * (1.0 - t * 0.3)
    phase = i * freq / sr
    return (triangle(phase) * 0.35 + square(phase * 0.5) * 0.15) * env * 0.8

# ---- BOSS ATTACK: heavy whoosh/grunt ----
def boss_attack_func(i, sr, n):
    t = i / n
    env = math.sin(t * math.pi) ** 0.5
    freq = 80 + 50 * math.sin(t * 30)
    phase = i * freq / sr
    return (square(phase) * 0.3 + noise() * 0.4) * env

# ---- BOSS DEFEATED: crash then triumph ----
def boss_defeated_func(i, sr, n):
    t = i / n
    if t < 0.4:
        # Crash/descending
        local_t = t / 0.4
        freq = 500 - 400 * local_t
        env = (1.0 - local_t) ** 0.5
        phase = i * freq / sr
        return (noise() * 0.4 + square(phase) * 0.3) * env
    elif t < 0.5:
        # Silence/pause
        return 0
    else:
        # Ascending triumph
        local_t = (t - 0.5) / 0.5
        triumph_notes = [392.00, 493.88, 587.33, 659.25, 783.99]
        note_idx = min(int(local_t * len(triumph_notes)), len(triumph_notes) - 1)
        freq = triumph_notes[note_idx]
        inner_t = (local_t * len(triumph_notes)) - note_idx
        env = max(0, 1.0 - inner_t * 0.5) * (1.0 - local_t * 0.2)
        phase = i * freq / sr
        return (square(phase) * 0.25 + triangle(phase) * 0.25) * env

# ---- EQUIP: sparkle/shine ----
def equip_func(i, sr, n):
    t = i / n
    # Shimmering high tones
    freq1 = 1200 + 400 * math.sin(t * 15 * math.pi)
    freq2 = 1800 + 300 * math.sin(t * 20 * math.pi + 1)
    env = math.sin(t * math.pi) ** 0.7
    phase1 = i * freq1 / sr
    phase2 = i * freq2 / sr
    return (triangle(phase1) * 0.25 + triangle(phase2) * 0.2 + noise() * 0.05) * env

# ---- Generate all SFX ----
print("Generating Sound Effects...")
sfx_list = [
    ("jump.wav", 0.2, jump_func),
    ("land.wav", 0.15, land_func),
    ("step.wav", 0.1, step_func),
    ("collect.wav", 0.3, collect_func),
    ("hurt.wav", 0.3, hurt_func),
    ("throw.wav", 0.25, throw_func),
    ("hit_enemy.wav", 0.3, hit_enemy_func),
    ("door.wav", 0.4, door_func),
    ("train_ambient.wav", 5.0, train_ambient_func),
    ("menu_select.wav", 0.1, menu_select_func),
    ("menu_confirm.wav", 0.2, menu_confirm_func),
    ("game_over.wav", 2.0, game_over_func),
    ("boss_attack.wav", 0.3, boss_attack_func),
    ("boss_defeated.wav", 3.0, boss_defeated_func),
    ("equip.wav", 0.4, equip_func),
]

for name, dur, func in sfx_list:
    path = os.path.join(SFX_DIR, name)
    generate_wav(path, SAMPLE_RATE, dur, func)

print(f"\nAll {len(sfx_list)} SFX files generated!")
