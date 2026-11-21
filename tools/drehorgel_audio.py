#!/usr/bin/env python3
"""Erzeugt alle Audio-Assets der Drehorgel-App – ohne externe Abhängigkeiten
(nur Python-Standardbibliothek, für mp3 zusätzlich ffmpeg).

    python3 tools/drehorgel_audio.py soundfont   # assets/soundfonts/drehorgel.sf2
    python3 tools/drehorgel_audio.py midi        # assets/rolls/*.mid + *.json
    python3 tools/drehorgel_audio.py mp3         # assets/rolls/*.mp3 (Web)
    python3 tools/drehorgel_audio.py all

Klang: synthetische Orgelpfeife (Flöte mit etwas Obertönen, "Chiff" beim
Einschwingen, leichtes Luftrauschen), zwei leicht gegeneinander verstimmte
Register (Schwebung wie bei echten Drehorgeln) und ein Tremulant.

Lieder: eigene, einfache Drehorgel-Arrangements gemeinfreier Melodien
(Melodie + Bass/Akkord-Begleitung "Hm-ta-ta"). Neue Lieder können unten in
SONGS ergänzt und in ROLLS (Notenrollen mit Strophenzahl) eingereiht werden.
"""
import array
import json
import math
import os
import random
import struct
import subprocess
import sys
import tempfile
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# --------------------------------------------------------------------------
# Klangparameter (gemeinsam für SoundFont und mp3-Rendering)
# --------------------------------------------------------------------------
HARMONICS = [1.0, 0.55, 0.30, 0.17, 0.10, 0.06, 0.035, 0.02, 0.012]
DETUNE_CENTS = 7          # zweites Register leicht höher -> Schwebung
LAYER2_GAIN_DB = -3.0
TREMOLO_HZ = 5.5
TREMOLO_DEPTH_DB = 1.5
ATTACK_S = 0.012
RELEASE_S = 0.09
NOISE_LEVEL = 0.015       # Luftrauschen


def note_freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def harmonics_for(freq, sr):
    """Obertöne oberhalb ~0.45*sr weglassen (kein Aliasing)."""
    return [(i + 1, a) for i, a in enumerate(HARMONICS) if freq * (i + 1) < 0.45 * sr]


# --------------------------------------------------------------------------
# SoundFont (.sf2)
# --------------------------------------------------------------------------
SF_RATE = 32000
SAMPLE_ROOTS = list(range(36, 97, 6))  # C2 .. C7, alle halbe Oktave


def make_pipe_sample(midi, sr, rng):
    """Liefert (pcm16-array, attack_len, loop_len, pitch_correction_cents).

    Die Schleife enthält eine ganze Zahl von Perioden, damit sie nahtlos ist;
    die minimale Frequenzabweichung wird per Pitch-Correction ausgeglichen.
    """
    target = note_freq(midi)
    best = None
    for L in range(int(0.15 * sr), int(0.25 * sr)):
        k = round(target * L / sr)
        if k < 1:
            continue
        f = sr * k / L
        err = 1200 * math.log2(f / target)
        if best is None or abs(err) < abs(best[0]):
            best = (err, L, f)
    cents_err, loop_len, freq = best
    attack_len = int(0.04 * sr)
    tail = 32
    total = attack_len + loop_len + tail

    # periodisches, tiefpassgefiltertes Rauschen (Länge = Schleife)
    raw = [rng.uniform(-1, 1) for _ in range(loop_len)]
    noise = [0.0] * loop_len
    y = 0.0
    for _ in range(2):  # zweimal durchlaufen -> nahtlos am Schleifenende
        for i in range(loop_len):
            y += 0.15 * (raw[i] - y)
            noise[i] = y

    harms = harmonics_for(freq, sr)
    chiff_tau = 0.010 * sr
    out = []
    for n in range(total):
        t = n / sr
        chiff = math.exp(-n / chiff_tau) if n < attack_len else 0.0
        v = 0.0
        for h, a in harms:
            boost = 1.0 + (1.5 * chiff if h in (2, 3) else 0.0)
            v += a * boost * math.sin(2 * math.pi * freq * h * t)
        v += NOISE_LEVEL * 6 * noise[n % loop_len]
        if chiff:
            v += 0.12 * chiff * rng.uniform(-1, 1)
        out.append(v)
    peak = max(abs(v) for v in out[attack_len:]) or 1.0
    scale = 0.6 * 32767 / peak
    pcm = array.array('h', (max(-32768, min(32767, int(v * scale))) for v in out))
    return pcm, attack_len, loop_len, -round(cents_err)


def _chunk(cid, data):
    if len(data) % 2:
        data += b'\0'
    return cid + struct.pack('<I', len(data)) + data


def _list(lid, payload):
    return _chunk(b'LIST', lid + payload)


def _name20(s):
    return s.encode('ascii')[:19].ljust(20, b'\0')


def _tc(seconds):
    return int(round(1200 * math.log2(seconds)))


def build_soundfont(path):
    rng = random.Random(1865)  # Gründungsjahr der Heilsarmee :-)
    smpl = bytearray()
    shdrs = []
    for idx, root in enumerate(SAMPLE_ROOTS):
        pcm, a_len, l_len, corr = make_pipe_sample(root, SF_RATE, rng)
        start = len(smpl) // 2
        smpl += pcm.tobytes()
        smpl += b'\0' * (46 * 2)
        shdrs.append(struct.pack(
            '<20sIIIIIBbHH', _name20('pipe%d' % root), start, start + len(pcm),
            start + a_len, start + a_len + l_len, SF_RATE, root, corr, 0, 1))
    shdrs.append(struct.pack('<20sIIIIIBbHH', _name20('EOS'), 0, 0, 0, 0, 0, 0, 0, 0, 0))

    def gen(oper, amount):
        return struct.pack('<Hh', oper, amount)

    def gen_range(oper, lo, hi):
        return struct.pack('<HBB', oper, lo, hi)

    igen = []
    ibag = []
    ranges = []
    for i, root in enumerate(SAMPLE_ROOTS):
        lo = 0 if i == 0 else root - 3
        hi = 127 if i == len(SAMPLE_ROOTS) - 1 else root + 2
        ranges.append((lo, hi))
    for layer in (0, 1):
        for i, (lo, hi) in enumerate(ranges):
            ibag.append(struct.pack('<HH', len(igen), 0))
            igen.append(gen_range(43, lo, hi))                    # keyRange
            igen.append(gen(34, _tc(ATTACK_S)))                    # attackVolEnv
            igen.append(gen(38, _tc(RELEASE_S)))                   # releaseVolEnv
            igen.append(gen(22, int(round(1200 * math.log2(TREMOLO_HZ / 8.176)))))  # freqModLFO
            igen.append(gen(13, int(TREMOLO_DEPTH_DB * 10)))       # modLfoToVolume (cB)
            igen.append(gen(16, 150))                              # reverbEffectsSend
            igen.append(gen(17, -150 if layer == 0 else 150))      # pan
            if layer == 1:
                igen.append(gen(52, DETUNE_CENTS))                 # fineTune
                igen.append(gen(48, int(-LAYER2_GAIN_DB * 10)))    # initialAttenuation
            igen.append(gen(54, 1))                                # sampleModes: loop
            igen.append(gen(53, i))                                # sampleID (zuletzt)
    ibag.append(struct.pack('<HH', len(igen), 0))
    igen.append(struct.pack('<HH', 0, 0))

    inst = [struct.pack('<20sH', _name20('Drehorgel'), 0),
            struct.pack('<20sH', _name20('EOI'), len(ibag) - 1)]
    pgen = [gen(41, 0), struct.pack('<HH', 0, 0)]                  # instrument 0
    pbag = [struct.pack('<HH', 0, 0), struct.pack('<HH', 1, 0)]
    phdr = [struct.pack('<20sHHHIII', _name20('Drehorgel'), 0, 0, 0, 0, 0, 0),
            struct.pack('<20sHHHIII', _name20('EOP'), 0, 0, 1, 0, 0, 0)]
    mod_term = b'\0' * 10

    info = _list(b'INFO',
                 _chunk(b'ifil', struct.pack('<HH', 2, 1)) +
                 _chunk(b'isng', b'EMU8000\0') +
                 _chunk(b'INAM', b'Drehorgel\0') +
                 _chunk(b'ICMT', b'Synthetisch erzeugt mit tools/drehorgel_audio.py\0'))
    sdta = _list(b'sdta', _chunk(b'smpl', bytes(smpl)))
    pdta = _list(b'pdta',
                 _chunk(b'phdr', b''.join(phdr)) +
                 _chunk(b'pbag', b''.join(pbag)) +
                 _chunk(b'pmod', mod_term) +
                 _chunk(b'pgen', b''.join(pgen)) +
                 _chunk(b'inst', b''.join(inst)) +
                 _chunk(b'ibag', b''.join(ibag)) +
                 _chunk(b'imod', mod_term) +
                 _chunk(b'igen', b''.join(igen)) +
                 _chunk(b'shdr', b''.join(shdrs)))
    body = b'sfbk' + info + sdta + pdta
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(b'RIFF' + struct.pack('<I', len(body)) + body)
    print('SoundFont: %s (%d KB, %d Samples)' % (path, os.path.getsize(path) // 1024, len(SAMPLE_ROOTS)))


# --------------------------------------------------------------------------
# Lieder: Notation
#   Melodie: "NOTE:DAUER" (Dauer in Viertelnoten), "R" = Pause, "|" = Takt
#   Akkorde: ein Eintrag pro Takt (ohne Auftakt), "C" oder "C:1 D7:2" (Schläge)
# --------------------------------------------------------------------------
SONGS = [
    dict(
        id='we_wish_you', title='We Wish You a Merry Christmas',
        meter=(3, 4), bpm=150, melody_shift=12,
        melody="""D4:1 |
            G4:1 G4:.5 A4:.5 G4:.5 F#4:.5 | E4:1 E4:1 E4:1 |
            A4:1 A4:.5 B4:.5 A4:.5 G4:.5 | F#4:1 D4:1 D4:1 |
            B4:1 B4:.5 C5:.5 B4:.5 A4:.5 | G4:1 E4:1 D4:.5 D4:.5 |
            E4:1 A4:1 F#4:1 | G4:2 R:1""",
        chords='G | C | A7 | D | B7 | Em | C:1 D7:2 | G',
    ),
    dict(
        id='jingle_bells', title='Jingle Bells',
        meter=(4, 4), bpm=150, melody_shift=12,
        melody="""
            B4:1 B4:1 B4:2 | B4:1 B4:1 B4:2 | B4:1 D5:1 G4:1.5 A4:.5 | B4:4 |
            C5:1 C5:1 C5:1.5 C5:.5 | C5:1 B4:1 B4:1 B4:.5 B4:.5 | B4:1 A4:1 A4:1 B4:1 | A4:2 D5:2 |
            B4:1 B4:1 B4:2 | B4:1 B4:1 B4:2 | B4:1 D5:1 G4:1.5 A4:.5 | B4:4 |
            C5:1 C5:1 C5:1.5 C5:.5 | C5:1 B4:1 B4:1 B4:.5 B4:.5 | D5:1 D5:1 C5:1 A4:1 | G4:3 R:1""",
        chords='G | G | G | G | C | G | A7 | D7 | G | G | G | G | C | G | D7 | G',
    ),
    dict(
        id='stille_nacht', title='Stille Nacht',
        meter=(6, 8), bpm=96, melody_shift=12,
        melody="""
            G4:1.5 A4:.5 G4:1 | E4:3 | G4:1.5 A4:.5 G4:1 | E4:3 |
            D5:2 D5:1 | B4:3 | C5:2 C5:1 | G4:3 |
            A4:2 A4:1 | C5:1.5 B4:.5 A4:1 | G4:1.5 A4:.5 G4:1 | E4:3 |
            A4:2 A4:1 | C5:1.5 B4:.5 A4:1 | G4:1.5 A4:.5 G4:1 | E4:3 |
            D5:2 D5:1 | F5:1.5 D5:.5 B4:1 | C5:3 | E5:3 |
            C5:1.5 G4:.5 E4:1 | G4:1.5 F4:.5 D4:1 | C4:3 | R:3""",
        chords="""C | C | C | C | G7 | G7 | C | C | F | F | C | C |
                  F | F | C | C | G7 | G7 | C | C | C | G7 | C | C""",
    ),
    dict(
        id='o_tannenbaum', title='O Tannenbaum',
        meter=(3, 4), bpm=110, melody_shift=12,
        melody="""C4:1 |
            F4:.75 F4:.25 F4:1.5 G4:.5 | A4:.75 A4:.25 A4:1.5 A4:.5 |
            G4:.5 A4:.5 Bb4:1 E4:1 | G4:1 F4:1 C5:1 |
            C5:.5 A4:.5 D5:1.5 C5:.5 | C5:.5 Bb4:.5 Bb4:1 Bb4:1 |
            Bb4:.5 G4:.5 C5:1.5 Bb4:.5 | Bb4:.5 A4:.5 A4:1 C4:1 |
            F4:.75 F4:.25 F4:1.5 G4:.5 | A4:.75 A4:.25 A4:1.5 A4:.5 |
            G4:.5 A4:.5 Bb4:1 E4:1 | G4:1 F4:1 R:1""",
        chords="""F | F | C7 | C7:1 F:2 | F | C7 | C7 | C7:1 F:2 |
                  F | F | C7 | C7:1 F:2""",
    ),
    dict(
        id='morgen_kommt', title='Morgen kommt der Weihnachtsmann',
        meter=(4, 4), bpm=120, melody_shift=12,
        melody="""
            C4:1 C4:1 G4:1 G4:1 | A4:1 A4:1 G4:2 | F4:1 F4:1 E4:1 E4:1 | D4:1 D4:1 C4:2 |
            G4:1 G4:1 F4:1 F4:1 | E4:1 E4:1 D4:2 | G4:1 G4:1 F4:1 F4:1 | E4:1 E4:1 D4:2 |
            C4:1 C4:1 G4:1 G4:1 | A4:1 A4:1 G4:2 | F4:1 F4:1 E4:1 E4:1 | D4:1 D4:1 C4:2""",
        chords="""C | F:2 C:2 | F:2 C:2 | G7:2 C:2 | C:2 F:2 | C:2 G7:2 | C:2 F:2 | C:2 G7:2 |
                  C | F:2 C:2 | F:2 C:2 | G7:2 C:2""",
    ),
    # ---- Standortlieder (Straßenmission) ----
    dict(
        id='amazing_grace', title='Amazing Grace',
        meter=(3, 4), bpm=96, melody_shift=12,
        melody="""D4:1 |
            G4:2 B4:.5 G4:.5 | B4:2 A4:1 | G4:2 E4:1 | D4:2 D4:1 |
            G4:2 B4:.5 G4:.5 | B4:2 A4:1 | D5:3~ | D5:2 B4:1 |
            D5:2 B4:.5 G4:.5 | B4:2 A4:1 | G4:2 E4:1 | D4:2 D4:1 |
            G4:2 B4:.5 G4:.5 | B4:2 A4:1 | G4:2 R:1""",
        chords="""G | G:2 D:1 | C | G | G | G:2 D:1 | D | G |
                  G | G:2 D:1 | C | G | G | G:2 D:1 | G""",
    ),
    dict(
        id='when_the_saints', title='When the Saints Go Marching In',
        meter=(4, 4), bpm=150, melody_shift=12,
        melody="""C4:1 E4:1 F4:1 |
            G4:4 | R:1 C4:1 E4:1 F4:1 | G4:4 | R:1 C4:1 E4:1 F4:1 |
            G4:2 E4:2 | C4:2 E4:2 | D4:4 | R:1 E4:1 E4:1 D4:1 |
            C4:3 C4:1 | E4:2 G4:2 | G4:1 F4:3 | R:1 E4:1 F4:1 G4:1 |
            E4:2 C4:2 | D4:4 | C4:4""",
        chords="""C | C | C | C | C | C | G7 | G7 | C | C | F | C | C | G7 | C""",
    ),
    dict(
        id='ode_an_die_freude', title='Ode an die Freude',
        meter=(4, 4), bpm=120, melody_shift=12,
        melody="""
            E4:1 E4:1 F4:1 G4:1 | G4:1 F4:1 E4:1 D4:1 | C4:1 C4:1 D4:1 E4:1 | E4:1.5 D4:.5 D4:2 |
            E4:1 E4:1 F4:1 G4:1 | G4:1 F4:1 E4:1 D4:1 | C4:1 C4:1 D4:1 E4:1 | D4:1.5 C4:.5 C4:2 |
            D4:1 D4:1 E4:1 C4:1 | D4:1 E4:.5 F4:.5 E4:1 C4:1 | D4:1 E4:.5 F4:.5 E4:1 D4:1 | C4:1 D4:1 G3:2 |
            E4:1 E4:1 F4:1 G4:1 | G4:1 F4:1 E4:1 D4:1 | C4:1 C4:1 D4:1 E4:1 | D4:1.5 C4:.5 C4:2""",
        chords="""C | G7 | C | C:2 G7:2 | C | G7 | C | G7:2 C:2 |
                  G7 | C | G7 | C:2 G7:2 | C | G7 | C | G7:2 C:2""",
    ),
    dict(
        id='michael_row', title='Michael, Row the Boat Ashore',
        meter=(4, 4), bpm=110, melody_shift=12,
        melody="""
            C4:1 E4:1 G4:1.5 E4:.5 | G4:1 A4:1 G4:2 | E4:1 G4:1 A4:2 | G4:4 |
            E4:1 G4:1 G4:1.5 E4:.5 | F4:1 E4:1 D4:2 | C4:1 D4:1 E4:2 | D4:2 C4:2""",
        chords="C | C | C:2 F:2 | C | C | Dm:2 G7:2 | C | G7:2 C:2",
    ),
]

# Notenrollen: (Lied-ID, Strophen). Wie ein echtes Lochband laufen die Lieder
# nacheinander durch; die letzte Strophe bekommt eine Oktavverdopplung.
ROLLS = [
    dict(id='weihnachten', title='Weihnachtsrolle',
         items=[('stille_nacht', 3), ('we_wish_you', 3), ('o_tannenbaum', 3),
                ('jingle_bells', 2), ('morgen_kommt', 2)]),
    dict(id='standort', title='Standortrolle',
         items=[('amazing_grace', 3), ('when_the_saints', 3),
                ('ode_an_die_freude', 2), ('michael_row', 3)]),
]
SONG_GAP_BEATS = 2

NOTE_BASE = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def parse_note(s):
    name = s[0]
    rest = s[1:]
    acc = 0
    while rest and rest[0] in '#b':
        acc += 1 if rest[0] == '#' else -1
        rest = rest[1:]
    return 12 * (int(rest) + 1) + NOTE_BASE[name] + acc


def parse_chord(sym):
    """'C', 'Am', 'G7', 'F#m' -> (root_pc, [intervalle])"""
    root = NOTE_BASE[sym[0]]
    q = sym[1:]
    if q.startswith('#'):
        root += 1
        q = q[1:]
    elif q.startswith('b'):
        root -= 1
        q = q[1:]
    ivs = {'': [0, 4, 7], 'm': [0, 3, 7], '7': [0, 4, 7, 10], 'm7': [0, 3, 7, 10]}[q]
    return root % 12, ivs


def bar_length(meter):
    num, den = meter
    return num * 4.0 / den


def parse_song(song):
    """-> Liste von (start, dauer, midi, velocity, channel) in Viertelnoten."""
    blen = bar_length(song['meter'])
    bars = [b.split() for b in song['melody'].split('|')]
    bars = [b for b in bars if b]
    chord_bars = [c.strip() for c in song['chords'].split('|')]
    notes = []
    t = 0.0
    bar_starts = []
    pickup = 0.0
    tie = None  # (start, gesamtdauer, key) einer per "~" gebundenen Note
    for bi, bar in enumerate(bars):
        bar_starts.append(t)
        length = 0.0
        for tok in bar:
            n, d = tok.split(':')
            tied = d.endswith('~')
            d = float(d.rstrip('~'))
            if n != 'R':
                key = parse_note(n) + song['melody_shift']
                if tie and tie[2] == key:
                    start, total = tie[0], tie[1] + d   # Haltebogen fortsetzen
                else:
                    start, total = t + length, d
                if tied:
                    tie = (start, total, key)
                else:
                    tie = None
                    notes.append((start, total - min(0.12 * d, 0.2), key, 100, 0))
            length += d
        if bi == 0 and length < blen - 1e-6:
            pickup = length
        elif abs(length - blen) > 1e-6:
            raise ValueError('%s: Takt %d hat %.2f statt %.2f Viertel' % (song['id'], bi + 1, length, blen))
        t += length
    full_bars = bar_starts[1:] if pickup else bar_starts
    if len(full_bars) != len(chord_bars):
        raise ValueError('%s: %d Takte, aber %d Akkord-Takte' % (song['id'], len(full_bars), len(chord_bars)))

    # Begleitmuster: (Zeitpunkt im Takt, 'bass'|'bass5'|'chord', Dauer)
    num, den = song['meter']
    if song['meter'] == (3, 4):
        pattern = [(0, 'bass', 1), (1, 'chord', 1), (2, 'chord', 1)]
    elif song['meter'] == (6, 8):
        pattern = [(0, 'bass', 1.5), (0.5, 'chord', .5), (1, 'chord', .5),
                   (1.5, 'bass5', 1.5), (2, 'chord', .5), (2.5, 'chord', .5)]
    else:
        pattern = [(0, 'bass', 1), (1, 'chord', 1), (2, 'bass5', 1), (3, 'chord', 1)]

    for start, spec in zip(full_bars, chord_bars):
        segs = []
        pos = 0.0
        for part in spec.split():
            if ':' in part:
                sym, beats = part.split(':')
                beats = float(beats) * (4.0 / den) if den == 8 else float(beats)
            else:
                sym, beats = part, blen
            segs.append((pos, sym))
            pos += beats
        for off, kind, dur in pattern:
            sym = [s for p, s in segs if p <= off + 1e-6][-1]
            root, ivs = parse_chord(sym)
            if kind in ('bass', 'bass5'):
                pc = root if kind == 'bass' else (root + 7) % 12
                key = 40 + (pc - 4) % 12          # E2..D#3
                notes.append((start + off, dur * 0.85, key, 82, 1))
            else:
                for iv in ivs[1:] if len(ivs) == 4 else ivs:
                    pc = (root + iv) % 12
                    key = 55 + (pc - 7) % 12      # G3..F#4
                    notes.append((start + off, dur * 0.6, key, 58, 1))
    total = t
    return notes, total, pickup


# --------------------------------------------------------------------------
# MIDI-Dateien
# --------------------------------------------------------------------------
PPQ = 480


def _vlq(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.append(0x80 | (n & 0x7F))
        n >>= 7
    return bytes(reversed(out))


def build_roll(roll):
    """Setzt eine Notenrolle zusammen.

    -> dict(notes=[(sek, dauer_sek, key, vel, ch)], segments=[...], total_sec,
            tempo_events=[(beat, bpm, meter)], total_beats, entries=[...])
    Zeiten liegen sowohl in Schlägen (für MIDI) als auch Sekunden (für mp3) vor.
    """
    by_id = {s['id']: s for s in SONGS}
    notes_beats = []   # (beat, dauer_beats, key, vel, ch)
    tempo_events = []  # (beat, bpm, meter)
    entries = []       # Index für die Anzeige
    beat = 0.0
    sec = 0.0
    seg_map = []       # (start_beat, start_sec, bpm) zur Umrechnung
    for song_id, verses in roll['items']:
        song = by_id[song_id]
        notes, total, _ = parse_song(song)
        tempo_events.append((beat, song['bpm'], song['meter']))
        seg_map.append((beat, sec, song['bpm']))
        for v in range(verses):
            entries.append(dict(title=song['title'], verse=v + 1, verses=verses,
                                tick=int(round(beat * PPQ)), sec=round(sec, 3)))
            last = v == verses - 1 and verses > 1
            for start, dur, key, vel, ch in notes:
                notes_beats.append((beat + start, dur, key, vel, ch))
                if last and ch == 0:  # letzte Strophe: Melodie in Oktaven
                    notes_beats.append((beat + start, dur, key - 12, 62, 2))
            beat += total
            sec += total * 60.0 / song['bpm']
        beat += SONG_GAP_BEATS
        sec += SONG_GAP_BEATS * 60.0 / song['bpm']

    def to_sec(b):
        seg = [x for x in seg_map if x[0] <= b + 1e-9][-1]
        return seg[1] + (b - seg[0]) * 60.0 / seg[2]

    notes_sec = []
    for b, d, key, vel, ch in notes_beats:
        s0 = to_sec(b)
        notes_sec.append((s0, to_sec(b + d) - s0, key, vel, ch))
    return dict(notes_beats=notes_beats, notes=notes_sec, tempo_events=tempo_events,
                total_beats=beat, total_sec=sec, entries=entries)


def write_roll_midi(roll, path):
    r = build_roll(roll)
    ev = []  # (tick, order, bytes)
    for b, dur, key, vel, ch in r['notes_beats']:
        on = int(round(b * PPQ))
        off = int(round((b + dur) * PPQ))
        ev.append((on, 2, bytes([0x90 | ch, key, vel])))
        ev.append((off, 1, bytes([0x80 | ch, key, 0])))
    for b, bpm, (num, den) in r['tempo_events']:
        t = int(round(b * PPQ))
        ev.append((t, 0, b'\xff\x51\x03' + int(60_000_000 / bpm).to_bytes(3, 'big')))
        ev.append((t, 0, b'\xff\x58\x04' + bytes([num, int(math.log2(den)), 24, 8])))
    ev.sort(key=lambda e: (e[0], e[1]))
    end_tick = int(round(r['total_beats'] * PPQ))

    trk = bytearray()
    title = roll['title'].encode('utf-8')
    trk += b'\x00\xff\x03' + _vlq(len(title)) + title
    for ch in (0, 1, 2):
        trk += bytes([0, 0xC0 | ch, 0])                 # Programm 0 = Drehorgel
    trk += bytes([0, 0xB1, 7, 96])                      # Begleitung etwas leiser
    last = 0
    for tick, _, data in ev:
        trk += _vlq(tick - last) + data
        last = tick
    trk += _vlq(max(0, end_tick - last)) + b'\xff\x2f\x00'
    hdr = b'MThd' + struct.pack('>IHHH', 6, 0, 1, PPQ)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(hdr + b'MTrk' + struct.pack('>I', len(trk)) + trk)

    index = dict(id=roll['id'], title=roll['title'], ppq=PPQ, totalTicks=end_tick,
                 durationSec=round(r['total_sec'], 3), entries=r['entries'])
    with open(path[:-4] + '.json', 'w', encoding='utf-8') as f:
        json.dump(index, f, ensure_ascii=False, indent=1)
    print('MIDI: %s (%d:%02d min, %d Strophen)' % (
        path, r['total_sec'] // 60, r['total_sec'] % 60, len(r['entries'])))


# --------------------------------------------------------------------------
# mp3-Rendering für die Web-Version (gleiche Klangsynthese, Wavetable)
# --------------------------------------------------------------------------
MP3_RATE = 22050
TABLE = 2048


def _wavetable(freq, sr):
    harms = harmonics_for(freq, sr)
    tab = [sum(a * math.sin(2 * math.pi * h * i / TABLE) for h, a in harms) for i in range(TABLE)]
    return tab


def render_roll(roll, path):
    r = build_roll(roll)
    sr = MP3_RATE
    length = int(r['total_sec'] * sr)
    buf = [0.0] * (length + int(RELEASE_S * 4 * sr))
    tables = {}
    g2 = 10 ** (LAYER2_GAIN_DB / 20)
    for start, dur, key, vel, ch in r['notes']:
        amp = (vel / 127.0) * (0.8 if ch == 1 else 1.0)
        for layer, cents, gain in ((0, 0, 1.0), (1, DETUNE_CENTS, g2)):
            f = note_freq(key) * 2 ** (cents / 1200)
            band = round(key / 6)
            if band not in tables:
                tables[band] = _wavetable(note_freq(band * 6), sr)
            tab = tables[band]
            n0 = int(start * sr)
            n_on = int(dur * sr)
            n_rel = int(RELEASE_S * sr)
            inc = f * TABLE / sr
            ph = 0.0
            a_len = max(1, int(ATTACK_S * sr))
            for n in range(n_on + n_rel):
                idx = n0 + n
                if idx >= len(buf):
                    break
                if n < a_len:
                    env = n / a_len
                elif n < n_on:
                    env = 1.0
                else:
                    env = math.exp(-(n - n_on) / (n_rel / 4))
                i = int(ph)
                frac = ph - i
                s = tab[i % TABLE] * (1 - frac) + tab[(i + 1) % TABLE] * frac
                buf[idx] += s * env * amp * gain
                ph += inc
                if ph >= TABLE:
                    ph -= TABLE
    # Tremulant + Luftrauschen + Normalisieren
    rng = random.Random(7)
    y = 0.0
    trem_depth = 1 - 10 ** (-TREMOLO_DEPTH_DB / 20)
    for n in range(len(buf)):
        trem = 1 - trem_depth * (0.5 + 0.5 * math.sin(2 * math.pi * TREMOLO_HZ * n / sr))
        y += 0.15 * (rng.uniform(-1, 1) - y)
        buf[n] = buf[n] * trem + (NOISE_LEVEL * y if abs(buf[n]) > 1e-3 else 0.0)
    buf = buf[:length]  # exakt Songlänge -> nahtlose Schleife im Player
    peak = max(abs(v) for v in buf) or 1.0
    pcm = array.array('h', (int(v / peak * 0.85 * 32767) for v in buf))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = os.path.join(tmp, 'song.wav')
        with wave.open(wav_path, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(sr)
            w.writeframes(pcm.tobytes())
        subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', wav_path,
                        '-codec:a', 'libmp3lame', '-b:a', '48k', path], check=True)
    print('mp3: %s (%d KB)' % (path, os.path.getsize(path) // 1024))


def main(argv):
    what = argv[1] if len(argv) > 1 else 'all'
    if what in ('soundfont', 'all'):
        build_soundfont(os.path.join(ROOT, 'assets/soundfonts/drehorgel.sf2'))
    if what in ('midi', 'all'):
        for r in ROLLS:
            write_roll_midi(r, os.path.join(ROOT, 'assets/rolls/%s.mid' % r['id']))
    if what in ('mp3', 'all'):
        for r in ROLLS:
            render_roll(r, os.path.join(ROOT, 'assets/rolls/%s.mp3' % r['id']))


if __name__ == '__main__':
    main(sys.argv)
