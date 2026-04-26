#!/usr/bin/env python3
"""
Neko_Funjatta.wav からメロディ (上声) のピッチを抽出する。

出力:
  --json-output: 抽出された MIDI 番号 + タイミングの JSON
  --wav-output:  矩形波合成された 8bit 風 WAV
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

import librosa
import numpy as np

from _chiptune import render_chiptune


CHATTER_MIN_SEC = 0.04


def hz_to_midi_round(hz: float) -> int:
    if hz <= 0 or not math.isfinite(hz):
        return -1
    return round(69 + 12 * math.log2(hz / 440.0))


def extract_melody(
    wav_path: Path,
    fmin: float = librosa.note_to_hz("C3"),
    fmax: float = librosa.note_to_hz("C7"),
    frame_length: int = 1024,
    hop_length: int = 256,
):
    y, sr = librosa.load(str(wav_path), sr=None, mono=True)
    print(f"loaded: {wav_path.name}, sr={sr}, duration={len(y)/sr:.2f}s")

    # pyin: 確率的 YIN。モノフォニックを仮定するが、ピアノ曲でも上声を比較的よく拾う。
    f0, voiced_flag, voiced_probs = librosa.pyin(
        y,
        fmin=fmin,
        fmax=fmax,
        sr=sr,
        frame_length=frame_length,
        hop_length=hop_length,
    )

    times = librosa.times_like(f0, sr=sr, hop_length=hop_length)

    # 各フレームを MIDI ノート番号に変換 (無音/未検出は -1)
    midis = np.array([hz_to_midi_round(h) if vf else -1
                      for h, vf in zip(f0, voiced_flag)], dtype=np.int32)

    # ノイズ除去: 1〜2フレームしか続かないノートを近傍で置換
    cleaned = midis.copy()
    for i in range(1, len(midis) - 1):
        if midis[i] != midis[i - 1] and midis[i] != midis[i + 1] and midis[i - 1] == midis[i + 1]:
            cleaned[i] = midis[i - 1]

    # 連続する同 MIDI フレームを 1 ノートに集約
    events = []
    if len(cleaned) == 0:
        return events, sr

    cur_midi = int(cleaned[0])
    cur_start_idx = 0
    for i in range(1, len(cleaned)):
        if int(cleaned[i]) != cur_midi:
            start_t = float(times[cur_start_idx])
            end_t = float(times[i])
            duration = end_t - start_t
            if cur_midi >= 0 and duration >= CHATTER_MIN_SEC:
                events.append({
                    "midi": cur_midi,
                    "start_sec": start_t,
                    "duration_sec": duration,
                })
            elif cur_midi < 0:
                events.append({
                    "midi": -1,
                    "start_sec": start_t,
                    "duration_sec": duration,
                })
            cur_midi = int(cleaned[i])
            cur_start_idx = i

    # 最後のセグメント
    start_t = float(times[cur_start_idx])
    end_t = float(times[-1])
    duration = end_t - start_t
    if cur_midi >= 0 and duration >= CHATTER_MIN_SEC:
        events.append({
            "midi": cur_midi,
            "start_sec": start_t,
            "duration_sec": duration,
        })

    # 連続する休符を統合
    merged = []
    for ev in events:
        if merged and ev["midi"] == -1 and merged[-1]["midi"] == -1:
            merged[-1]["duration_sec"] += ev["duration_sec"]
        else:
            merged.append(ev)

    return merged, sr


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--json-output", type=Path, required=True)
    parser.add_argument("--wav-output", type=Path, required=True)
    args = parser.parse_args()

    events, sr = extract_melody(args.input)

    args.json_output.parent.mkdir(parents=True, exist_ok=True)
    with args.json_output.open("w") as f:
        json.dump({"sample_rate": sr, "events": events}, f, indent=2)

    note_count = sum(1 for e in events if e["midi"] >= 0)
    rest_count = sum(1 for e in events if e["midi"] < 0)
    total = sum(e["duration_sec"] for e in events)
    print(f"events: {len(events)} (notes={note_count}, rests={rest_count})")
    print(f"total duration: {total:.2f}s")
    print(f"wrote JSON: {args.json_output}")

    print("\nfirst 12 events:")
    for ev in events[:12]:
        if ev["midi"] >= 0:
            note = librosa.midi_to_note(ev["midi"])
            print(f"  t={ev['start_sec']:.3f}s  MIDI={ev['midi']:3d} ({note:>4})  dur={ev['duration_sec']:.3f}s")
        else:
            print(f"  t={ev['start_sec']:.3f}s  REST              dur={ev['duration_sec']:.3f}s")

    args.wav_output.parent.mkdir(parents=True, exist_ok=True)
    render_chiptune(events, args.wav_output)


if __name__ == "__main__":
    main()
