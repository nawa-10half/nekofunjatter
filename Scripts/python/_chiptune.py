"""8bit 風 (矩形波 + 量子化) シンセ。extract_melody / synth_8bit から共有。"""

from __future__ import annotations

from pathlib import Path

import numpy as np

from _audio_io import write_int16_wav


def midi_to_freq(midi: int) -> float:
    return 440.0 * (2.0 ** ((midi - 69) / 12.0))


def render_chiptune(
    events: list[dict],
    output_path: Path,
    sample_rate: int = 44100,
    duty: float = 0.5,
    amplitude: float = 0.25,
    quantize_levels: int = 127,
    attack_sec: float = 0.003,
    release_sec: float = 0.025,
) -> None:
    """events を矩形波で合成し WAV に書き出す。
    各イベントは {"midi": int, "start_sec": float, "duration_sec": float}。
    midi < 0 は休符。
    """
    if not events:
        return

    total_dur = max(ev["start_sec"] + ev["duration_sec"] for ev in events) + 0.3
    samples = np.zeros(int(total_dur * sample_rate), dtype=np.float32)

    for ev in events:
        if ev["midi"] < 0:
            continue
        freq = midi_to_freq(ev["midi"])
        start_idx = int(ev["start_sec"] * sample_rate)
        n = int(ev["duration_sec"] * sample_rate)
        if n <= 0 or start_idx >= len(samples):
            continue
        end_idx = min(start_idx + n, len(samples))
        actual_n = end_idx - start_idx

        t = np.arange(actual_n) / sample_rate
        phase = (freq * t) % 1.0
        wave = np.where(phase < duty, 1.0, -1.0).astype(np.float32)

        env = np.ones(actual_n, dtype=np.float32)
        attack_n = min(int(attack_sec * sample_rate), actual_n // 4)
        release_n = min(int(release_sec * sample_rate), actual_n // 3)
        if attack_n > 0:
            env[:attack_n] = np.linspace(0.0, 1.0, attack_n, dtype=np.float32)
        if release_n > 0:
            env[-release_n:] = np.linspace(1.0, 0.0, release_n, dtype=np.float32)

        samples[start_idx:end_idx] += wave * env * amplitude

    # 量子化でチップチューン感を強める
    samples = np.clip(samples, -1.0, 1.0)
    quantized = np.round(samples * quantize_levels) / quantize_levels

    write_int16_wav(output_path, quantized, sample_rate)
    print(f"wrote 8bit WAV: {output_path} ({total_dur:.2f}s @ {sample_rate}Hz)")
