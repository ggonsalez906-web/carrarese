import struct, math, wave, random, os

SAMPLE_RATE = 22050
MUSIC_DIR = os.path.join(os.path.dirname(__file__), "assets", "audio", "music")
os.makedirs(MUSIC_DIR, exist_ok=True)

def write_wav(filename, samples, sample_rate=22050):
    samples = [max(-1.0, min(1.0, s)) for s in samples]
    int_samples = [int(s * 32767) for s in samples]
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        # Write in chunks to avoid huge struct pack
        chunk_size = 10000
        for ci in range(0, len(int_samples), chunk_size):
            chunk = int_samples[ci:ci+chunk_size]
            f.writeframes(struct.pack('<' + 'h' * len(chunk), *chunk))
    dur = len(samples) / sample_rate
    print(f"  Created: {os.path.basename(filename)} ({dur:.1f}s, {os.path.getsize(filename)} bytes)")

def square_wave(phase, duty=0.5):
    return 1.0 if (phase % 1.0) < duty else -1.0

def triangle_wave(phase):
    p = phase % 1.0
    if p < 0.25: return p * 4.0
    elif p < 0.75: return 2.0 - p * 4.0
    else: return p * 4.0 - 4.0

def pulse_wave(phase, width=0.25):
    return 1.0 if (phase % 1.0) < width else -1.0

def noise_val():
    return random.uniform(-1, 1)

def note_freq(name):
    """Get frequency for note name like C4, D#5, etc."""
    notes = {'C':0,'C#':1,'Db':1,'D':2,'D#':3,'Eb':3,'E':4,'F':5,'F#':6,'Gb':6,'G':7,'G#':8,'Ab':8,'A':9,'A#':10,'Bb':10,'B':11}
    if len(name) == 2:
        n, octave = name[0], int(name[1])
    else:
        n, octave = name[:2], int(name[2])
    semitone = notes[n] + (octave - 4) * 12 - 9  # relative to A4
    return 440.0 * (2.0 ** (semitone / 12.0))

# ============================================================
# MENU THEME: ~30s, 120 BPM, major key, NES-style
# ============================================================
def gen_menu_theme():
    print("Generating menu_theme.wav...")
    bpm = 120
    beat_dur = 60.0 / bpm
    sr = SAMPLE_RATE
    duration = 30.0
    n_samples = int(sr * duration)
    samples = [0.0] * n_samples

    # Melody: upbeat C major chiptune melody
    # Pattern repeats every 8 bars (16 seconds at 120bpm)
    melody_pattern = [
        # (note, duration_in_beats)
        ('C5', 1), ('E5', 1), ('G5', 1), ('C6', 1),
        ('B5', 0.5), ('A5', 0.5), ('G5', 1), ('E5', 1),
        ('F5', 1), ('A5', 1), ('G5', 1), ('E5', 0.5), ('D5', 0.5),
        ('C5', 1), ('D5', 1), ('E5', 1), ('G5', 1),
        # Second phrase
        ('A5', 1), ('G5', 0.5), ('F5', 0.5), ('E5', 1), ('C5', 1),
        ('D5', 1), ('F5', 1), ('E5', 1), ('G5', 0.5), ('A5', 0.5),
        ('C6', 1.5), ('B5', 0.5), ('A5', 1), ('G5', 1),
        ('E5', 1), ('D5', 0.5), ('C5', 0.5), ('C5', 2),
    ]

    # Bass pattern
    bass_pattern = [
        ('C3', 2), ('G3', 2), ('A3', 2), ('E3', 2),
        ('F3', 2), ('C3', 2), ('G3', 2), ('C3', 2),
        ('F3', 2), ('G3', 2), ('A3', 2), ('E3', 2),
        ('F3', 2), ('G3', 2), ('C3', 4),
    ]

    # Render melody (square wave)
    t_beats = 0
    for note, dur_beats in melody_pattern * 3:  # repeat to fill ~30s
        start_sample = int(t_beats * beat_dur * sr)
        end_sample = int((t_beats + dur_beats) * beat_dur * sr)
        if start_sample >= n_samples:
            break
        end_sample = min(end_sample, n_samples)
        freq = note_freq(note)
        note_len = end_sample - start_sample
        for j in range(start_sample, end_sample):
            local_t = (j - start_sample) / note_len
            env = min(1.0, (1.0 - local_t) * 3) * min(1.0, local_t * 50)
            phase = (j - start_sample) * freq / sr
            samples[j] += square_wave(phase) * 0.22 * env
        t_beats += dur_beats

    # Render bass (triangle wave)
    t_beats = 0
    for note, dur_beats in bass_pattern * 5:
        start_sample = int(t_beats * beat_dur * sr)
        end_sample = int((t_beats + dur_beats) * beat_dur * sr)
        if start_sample >= n_samples:
            break
        end_sample = min(end_sample, n_samples)
        freq = note_freq(note)
        note_len = end_sample - start_sample
        for j in range(start_sample, end_sample):
            local_t = (j - start_sample) / note_len
            env = min(1.0, (1.0 - local_t) * 2) * min(1.0, local_t * 30)
            phase = (j - start_sample) * freq / sr
            samples[j] += triangle_wave(phase) * 0.2 * env
        t_beats += dur_beats

    # Render percussion (noise hihat on every beat, kick on 1 and 3)
    total_beats = int(duration / beat_dur)
    for b in range(total_beats):
        # Hihat
        start = int(b * beat_dur * sr)
        hihat_len = int(0.05 * sr)
        for j in range(hihat_len):
            idx = start + j
            if idx < n_samples:
                env = (1.0 - j / hihat_len) ** 3
                samples[idx] += noise_val() * 0.08 * env
        # Kick on beats 0, 2 of each measure (4-beat measure)
        if b % 4 in [0, 2]:
            kick_len = int(0.08 * sr)
            for j in range(kick_len):
                idx = start + j
                if idx < n_samples:
                    t_k = j / kick_len
                    freq_k = 150 * (1.0 - t_k * 0.7)
                    env = (1.0 - t_k) ** 2
                    phase = j * freq_k / sr
                    samples[idx] += triangle_wave(phase) * 0.18 * env

    write_wav(os.path.join(MUSIC_DIR, "menu_theme.wav"), samples, sr)

# ============================================================
# TRAIN THEME: ~45s, rhythmic with chugging beat
# ============================================================
def gen_train_theme():
    print("Generating train_theme.wav...")
    bpm = 110
    beat_dur = 60.0 / bpm
    sr = SAMPLE_RATE
    duration = 45.0
    n_samples = int(sr * duration)
    samples = [0.0] * n_samples

    # Melody: more driving, repetitive train-feel
    melody_pattern = [
        ('E4', 0.5), ('E4', 0.5), ('G4', 1), ('A4', 0.5), ('G4', 0.5),
        ('E4', 1), ('D4', 1), ('E4', 1), ('G4', 0.5), ('A4', 0.5),
        ('B4', 1), ('A4', 0.5), ('G4', 0.5), ('E4', 1), ('D4', 1),
        ('C4', 1), ('D4', 1), ('E4', 2),
        # Second phrase
        ('G4', 0.5), ('G4', 0.5), ('A4', 1), ('B4', 0.5), ('A4', 0.5),
        ('G4', 1), ('E4', 1), ('G4', 1), ('A4', 0.5), ('B4', 0.5),
        ('C5', 1), ('B4', 0.5), ('A4', 0.5), ('G4', 1), ('E4', 1),
        ('D4', 1), ('E4', 1), ('E4', 2),
    ]

    bass_pattern = [
        ('E2', 1), ('E2', 1), ('E2', 1), ('E2', 1),
        ('A2', 1), ('A2', 1), ('B2', 1), ('B2', 1),
        ('C3', 1), ('C3', 1), ('B2', 1), ('A2', 1),
        ('E2', 1), ('E2', 1), ('E2', 2),
    ]

    # Melody (pulse wave for different timbre)
    t_beats = 0
    for note, dur_beats in melody_pattern * 4:
        start_sample = int(t_beats * beat_dur * sr)
        end_sample = int((t_beats + dur_beats) * beat_dur * sr)
        if start_sample >= n_samples: break
        end_sample = min(end_sample, n_samples)
        freq = note_freq(note)
        note_len = end_sample - start_sample
        for j in range(start_sample, end_sample):
            local_t = (j - start_sample) / note_len
            env = min(1.0, (1.0 - local_t) * 3) * min(1.0, local_t * 50)
            phase = (j - start_sample) * freq / sr
            samples[j] += pulse_wave(phase, 0.25) * 0.2 * env
        t_beats += dur_beats

    # Bass
    t_beats = 0
    for note, dur_beats in bass_pattern * 6:
        start_sample = int(t_beats * beat_dur * sr)
        end_sample = int((t_beats + dur_beats) * beat_dur * sr)
        if start_sample >= n_samples: break
        end_sample = min(end_sample, n_samples)
        freq = note_freq(note)
        note_len = end_sample - start_sample
        for j in range(start_sample, end_sample):
            local_t = (j - start_sample) / note_len
            env = min(1.0, (1.0 - local_t) * 2) * min(1.0, local_t * 30)
            phase = (j - start_sample) * freq / sr
            samples[j] += triangle_wave(phase) * 0.18 * env
        t_beats += dur_beats

    # Chugging rhythm — eighth note pulse
    eighth = beat_dur / 2
    total_eighths = int(duration / eighth)
    for e in range(total_eighths):
        start = int(e * eighth * sr)
        chug_len = int(0.04 * sr)
        for j in range(chug_len):
            idx = start + j
            if idx < n_samples:
                t_c = j / chug_len
                env = (1.0 - t_c) ** 4
                # Alternating volume for train feel: strong-weak
                vol = 0.12 if e % 2 == 0 else 0.06
                samples[idx] += noise_val() * vol * env

    # Kick drum on each beat
    total_beats = int(duration / beat_dur)
    for b in range(total_beats):
        start = int(b * beat_dur * sr)
        kick_len = int(0.06 * sr)
        for j in range(kick_len):
            idx = start + j
            if idx < n_samples:
                t_k = j / kick_len
                freq_k = 80 * (1.0 - t_k * 0.5)
                env = (1.0 - t_k) ** 2
                phase = j * freq_k / sr
                samples[idx] += triangle_wave(phase) * 0.15 * env

    write_wav(os.path.join(MUSIC_DIR, "train_theme.wav"), samples, sr)

# ============================================================
# BOSS THEME: ~30s, 150 BPM, minor key, intense
# ============================================================
def gen_boss_theme():
    print("Generating boss_theme.wav...")
    bpm = 150
    beat_dur = 60.0 / bpm
    sr = SAMPLE_RATE
    duration = 30.0
    n_samples = int(sr * duration)
    samples = [0.0] * n_samples

    # Melody: E minor, intense, fast arpeggios
    melody_pattern = [
        ('E5', 0.5), ('G5', 0.5), ('B5', 0.5), ('E6', 0.5),
        ('D6', 0.5), ('B5', 0.5), ('G5', 0.5), ('E5', 0.5),
        ('D#5', 0.5), ('F#5', 0.5), ('A5', 0.5), ('D#6', 0.5),
        ('C6', 0.5), ('A5', 0.5), ('F#5', 0.5), ('D#5', 0.5),
        # Second phrase - more dramatic
        ('E5', 0.25), ('E5', 0.25), ('G5', 0.5), ('B5', 0.5), ('E6', 1),
        ('D6', 0.5), ('C6', 0.5), ('B5', 0.5), ('A5', 0.5),
        ('G5', 0.5), ('F#5', 0.5), ('E5', 1), ('D5', 0.5), ('E5', 0.5),
        ('E5', 1), ('G5', 0.5), ('B5', 0.5), ('E5', 1),
    ]

    bass_pattern = [
        ('E2', 1), ('E2', 0.5), ('E2', 0.5), ('G2', 1), ('A2', 1),
        ('B2', 1), ('B2', 0.5), ('B2', 0.5), ('A2', 1), ('G2', 1),
        ('E2', 1), ('E2', 0.5), ('E2', 0.5), ('D2', 1), ('E2', 1),
        ('E2', 2), ('G2', 1), ('E2', 1),
    ]

    # Melody (square wave)
    t_beats = 0
    for note, dur_beats in melody_pattern * 5:
        start_sample = int(t_beats * beat_dur * sr)
        end_sample = int((t_beats + dur_beats) * beat_dur * sr)
        if start_sample >= n_samples: break
        end_sample = min(end_sample, n_samples)
        freq = note_freq(note)
        note_len = max(1, end_sample - start_sample)
        for j in range(start_sample, end_sample):
            local_t = (j - start_sample) / note_len
            env = min(1.0, (1.0 - local_t) * 4) * min(1.0, local_t * 80)
            phase = (j - start_sample) * freq / sr
            samples[j] += square_wave(phase) * 0.22 * env
        t_beats += dur_beats

    # Heavy bass (square + triangle)
    t_beats = 0
    for note, dur_beats in bass_pattern * 6:
        start_sample = int(t_beats * beat_dur * sr)
        end_sample = int((t_beats + dur_beats) * beat_dur * sr)
        if start_sample >= n_samples: break
        end_sample = min(end_sample, n_samples)
        freq = note_freq(note)
        note_len = max(1, end_sample - start_sample)
        for j in range(start_sample, end_sample):
            local_t = (j - start_sample) / note_len
            env = min(1.0, (1.0 - local_t) * 2.5) * min(1.0, local_t * 30)
            phase = (j - start_sample) * freq / sr
            samples[j] += (square_wave(phase, 0.3) * 0.12 + triangle_wave(phase) * 0.15) * env
        t_beats += dur_beats

    # Fast percussion - sixteenth note hihat
    sixteenth = beat_dur / 4
    total_16ths = int(duration / sixteenth)
    for s16 in range(total_16ths):
        start = int(s16 * sixteenth * sr)
        hat_len = int(0.02 * sr)
        for j in range(hat_len):
            idx = start + j
            if idx < n_samples:
                env = (1.0 - j / hat_len) ** 4
                vol = 0.1 if s16 % 4 == 0 else 0.04
                samples[idx] += noise_val() * vol * env

    # Kick on 1 and 3, snare on 2 and 4
    total_beats = int(duration / beat_dur)
    for b in range(total_beats):
        start = int(b * beat_dur * sr)
        if b % 4 in [0, 2]:  # kick
            kick_len = int(0.06 * sr)
            for j in range(kick_len):
                idx = start + j
                if idx < n_samples:
                    t_k = j / kick_len
                    freq_k = 100 * (1.0 - t_k * 0.6)
                    env = (1.0 - t_k) ** 2
                    phase = j * freq_k / sr
                    samples[idx] += triangle_wave(phase) * 0.2 * env
        if b % 4 in [1, 3]:  # snare
            snare_len = int(0.08 * sr)
            for j in range(snare_len):
                idx = start + j
                if idx < n_samples:
                    t_s = j / snare_len
                    env = (1.0 - t_s) ** 2
                    samples[idx] += noise_val() * 0.15 * env

    write_wav(os.path.join(MUSIC_DIR, "boss_theme.wav"), samples, sr)

# ============================================================
# VICTORY THEME: ~15s, triumphant fanfare
# ============================================================
def gen_victory_theme():
    print("Generating victory_theme.wav...")
    bpm = 130
    beat_dur = 60.0 / bpm
    sr = SAMPLE_RATE
    duration = 15.0
    n_samples = int(sr * duration)
    samples = [0.0] * n_samples

    # Triumphant ascending melody in C major
    melody_pattern = [
        ('C5', 0.5), ('C5', 0.5), ('C5', 0.5), ('C5', 1.5),
        ('Ab4', 1), ('Bb4', 1), ('C5', 1.5), ('Bb4', 0.5), ('C5', 2),
        # Ascending fanfare
        ('C5', 0.5), ('D5', 0.5), ('E5', 0.5), ('F5', 0.5),
        ('G5', 1), ('A5', 1), ('G5', 0.5), ('A5', 0.5),
        ('B5', 1), ('C6', 2), ('C6', 1),
        # Final flourish
        ('G5', 0.25), ('A5', 0.25), ('B5', 0.25), ('C6', 0.25),
        ('E6', 2), ('C6', 2),
    ]

    bass_pattern = [
        ('C3', 2), ('C3', 2), ('Ab2', 2), ('Bb2', 2),
        ('C3', 2), ('F3', 2), ('G3', 2), ('C3', 4),
        ('C3', 2), ('C3', 2),
    ]

    # Melody (square wave, bright)
    t_beats = 0
    for note, dur_beats in melody_pattern:
        start_sample = int(t_beats * beat_dur * sr)
        end_sample = int((t_beats + dur_beats) * beat_dur * sr)
        if start_sample >= n_samples: break
        end_sample = min(end_sample, n_samples)
        freq = note_freq(note)
        note_len = max(1, end_sample - start_sample)
        for j in range(start_sample, end_sample):
            local_t = (j - start_sample) / note_len
            env = min(1.0, (1.0 - local_t) * 3) * min(1.0, local_t * 60)
            phase = (j - start_sample) * freq / sr
            samples[j] += (square_wave(phase) * 0.2 + triangle_wave(phase * 2) * 0.1) * env
        t_beats += dur_beats

    # Harmony layer - thirds above
    harmony_pattern = [
        ('E5', 0.5), ('E5', 0.5), ('E5', 0.5), ('E5', 1.5),
        ('C5', 1), ('D5', 1), ('E5', 1.5), ('D5', 0.5), ('E5', 2),
        ('E5', 0.5), ('F5', 0.5), ('G5', 0.5), ('A5', 0.5),
        ('B5', 1), ('C6', 1), ('B5', 0.5), ('C6', 0.5),
        ('D6', 1), ('E6', 2), ('E6', 1),
        ('B5', 0.25), ('C6', 0.25), ('D6', 0.25), ('E6', 0.25),
        ('G6', 2), ('E6', 2),
    ]
    t_beats = 0
    for note, dur_beats in harmony_pattern:
        start_sample = int(t_beats * beat_dur * sr)
        end_sample = int((t_beats + dur_beats) * beat_dur * sr)
        if start_sample >= n_samples: break
        end_sample = min(end_sample, n_samples)
        freq = note_freq(note)
        note_len = max(1, end_sample - start_sample)
        for j in range(start_sample, end_sample):
            local_t = (j - start_sample) / note_len
            env = min(1.0, (1.0 - local_t) * 3) * min(1.0, local_t * 60)
            phase = (j - start_sample) * freq / sr
            samples[j] += triangle_wave(phase) * 0.12 * env
        t_beats += dur_beats

    # Bass
    t_beats = 0
    for note, dur_beats in bass_pattern:
        start_sample = int(t_beats * beat_dur * sr)
        end_sample = int((t_beats + dur_beats) * beat_dur * sr)
        if start_sample >= n_samples: break
        end_sample = min(end_sample, n_samples)
        freq = note_freq(note)
        note_len = max(1, end_sample - start_sample)
        for j in range(start_sample, end_sample):
            local_t = (j - start_sample) / note_len
            env = min(1.0, (1.0 - local_t) * 2) * min(1.0, local_t * 30)
            phase = (j - start_sample) * freq / sr
            samples[j] += triangle_wave(phase) * 0.2 * env
        t_beats += dur_beats

    # Cymbal crashes at key moments
    crash_beats = [0, 4, 8, 12]
    for cb in crash_beats:
        start = int(cb * beat_dur * sr)
        crash_len = int(1.0 * sr)
        for j in range(crash_len):
            idx = start + j
            if idx < n_samples:
                t_c = j / crash_len
                env = (1.0 - t_c) ** 1.5
                samples[idx] += noise_val() * 0.06 * env

    write_wav(os.path.join(MUSIC_DIR, "victory_theme.wav"), samples, sr)

# ============================================================
# STADIUM AMBIENCE: ~20s, crowd + drums
# ============================================================
def gen_stadium_ambience():
    print("Generating stadium_ambience.wav...")
    sr = SAMPLE_RATE
    duration = 20.0
    n_samples = int(sr * duration)
    samples = [0.0] * n_samples

    random.seed(42)  # reproducible

    # Base crowd noise: filtered noise with slow modulation
    for i in range(n_samples):
        t = i / sr
        # Crowd roar: modulated noise
        crowd_mod = 0.5 + 0.3 * math.sin(t * 0.5 * math.pi) + 0.2 * math.sin(t * 1.3 * math.pi)
        samples[i] += noise_val() * 0.12 * crowd_mod

    # Apply simple low-pass to crowd (averaging filter)
    window = 8
    smoothed = [0.0] * n_samples
    running_sum = sum(samples[:window])
    for i in range(n_samples):
        if i >= window:
            running_sum -= samples[i - window]
        if i < n_samples:
            running_sum += samples[min(i + window - 1, n_samples - 1)] if i + window - 1 < n_samples else 0
        smoothed[i] = running_sum / window
    samples = smoothed

    # Stadium drums: boom-boom-clap pattern, repeating
    pattern_dur = 1.5  # seconds per pattern
    n_patterns = int(duration / pattern_dur)
    for p in range(n_patterns):
        base = p * pattern_dur
        # Boom at 0, 0.375
        for boom_t in [0, 0.375]:
            start = int((base + boom_t) * sr)
            boom_len = int(0.1 * sr)
            for j in range(boom_len):
                idx = start + j
                if idx < n_samples:
                    t_b = j / boom_len
                    freq = 80 * (1.0 - t_b * 0.4)
                    env = (1.0 - t_b) ** 2
                    phase = j * freq / sr
                    samples[idx] += triangle_wave(phase) * 0.25 * env
        # Clap at 0.75
        clap_start = int((base + 0.75) * sr)
        clap_len = int(0.06 * sr)
        for j in range(clap_len):
            idx = clap_start + j
            if idx < n_samples:
                t_c = j / clap_len
                env = (1.0 - t_c) ** 3
                samples[idx] += noise_val() * 0.2 * env

    # Occasional crowd surges (cheers)
    for surge_t in [3.0, 7.5, 12.0, 16.5]:
        start = int(surge_t * sr)
        surge_len = int(2.0 * sr)
        for j in range(surge_len):
            idx = start + j
            if idx < n_samples:
                t_s = j / surge_len
                env = math.sin(t_s * math.pi) ** 0.5
                # Higher pitched noise for cheering
                freq = 400 + 200 * math.sin(t_s * 10)
                phase = j * freq / sr
                samples[idx] += (noise_val() * 0.08 + triangle_wave(phase) * 0.03) * env

    # Chanting "ooh" - simple tone swell
    for chant_t in [5.0, 10.0, 15.0]:
        start = int(chant_t * sr)
        chant_len = int(1.5 * sr)
        for j in range(chant_len):
            idx = start + j
            if idx < n_samples:
                t_ch = j / chant_len
                env = math.sin(t_ch * math.pi) * 0.15
                freq = 220 + 20 * math.sin(t_ch * 4 * math.pi)
                phase = j * freq / sr
                samples[idx] += triangle_wave(phase) * env

    write_wav(os.path.join(MUSIC_DIR, "stadium_ambience.wav"), samples, sr)

# ============================================================
# Generate all music
# ============================================================
print("=== Generating Music Tracks ===")
gen_menu_theme()
gen_train_theme()
gen_boss_theme()
gen_victory_theme()
gen_stadium_ambience()
print("\nAll 5 music tracks generated!")
