#!/usr/bin/env python3
"""WAV ファイルをピッチシフト (semitone 単位)。長さは保持される。"""

from __future__ import annotations

import argparse
from pathlib import Path

import librosa
import numpy as np
from scipy.io import wavfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--semitones", type=float, default=12.0,
                        help="シフト量 (半音単位)。+12 で 1 オクターブ上、-12 で下。")
    args = parser.parse_args()

    print(f"loading: {args.input}")
    y, sr = librosa.load(str(args.input), sr=None, mono=False)

    if y.ndim == 1:
        shifted = librosa.effects.pitch_shift(y, sr=sr, n_steps=args.semitones)
    else:
        # ステレオ: チャンネルごとに処理
        shifted = np.stack([
            librosa.effects.pitch_shift(ch, sr=sr, n_steps=args.semitones)
            for ch in y
        ])

    # int16 PCM として書き出し
    shifted_clipped = np.clip(shifted, -1.0, 1.0)
    pcm = (shifted_clipped * 32767.0).astype(np.int16)

    if pcm.ndim > 1:
        # scipy.io.wavfile は (n_samples, n_channels) 形式を期待
        pcm = pcm.T

    args.output.parent.mkdir(parents=True, exist_ok=True)
    wavfile.write(str(args.output), sr, pcm)
    print(f"wrote: {args.output} ({args.semitones:+.1f} semitones)")


if __name__ == "__main__":
    main()
