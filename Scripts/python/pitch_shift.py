#!/usr/bin/env python3
"""WAV ファイルをピッチシフト (semitone 単位)。長さは保持される。"""

from __future__ import annotations

import argparse
from pathlib import Path

import librosa

from _audio_io import write_int16_wav


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--semitones", type=float, default=12.0,
                        help="シフト量 (半音単位)。+12 で 1 オクターブ上、-12 で下。")
    args = parser.parse_args()

    print(f"loading: {args.input}")
    y, sr = librosa.load(str(args.input), sr=None, mono=False)

    # librosa.effects.pitch_shift は多チャンネル (axis=-1) を直接受け付ける
    shifted = librosa.effects.pitch_shift(y, sr=sr, n_steps=args.semitones)

    write_int16_wav(args.output, shifted, sr)
    print(f"wrote: {args.output} ({args.semitones:+.1f} semitones)")


if __name__ == "__main__":
    main()
