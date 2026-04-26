#!/usr/bin/env python3
"""WAV の前後の無音をトリムし、ループ用の極短フェードを付ける。"""

from __future__ import annotations

import argparse
from pathlib import Path

import librosa
import numpy as np

from _audio_io import write_int16_wav


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--top-db", type=float, default=30.0,
                        help="無音判定の閾値 (dB)。値が大きいほど多く残る。")
    parser.add_argument("--fade-ms", type=float, default=8.0,
                        help="ループ時のクリック防止フェード (ms)")
    args = parser.parse_args()

    y, sr = librosa.load(str(args.input), sr=None, mono=False)
    print(f"loaded: {args.input.name}, sr={sr}, original={(y.shape[-1])/sr:.3f}s")

    y_mono = y if y.ndim == 1 else np.mean(y, axis=0)
    _, idx = librosa.effects.trim(y_mono, top_db=args.top_db)
    start, end = idx[0], idx[1]
    trimmed = y[start:end] if y.ndim == 1 else y[:, start:end]

    # ループ時のクリックノイズ防止: ごく短いフェードイン/アウト
    fade_n = max(1, int(args.fade_ms / 1000.0 * sr))
    fade_in = np.linspace(0.0, 1.0, fade_n, dtype=np.float32)
    fade_out = np.linspace(1.0, 0.0, fade_n, dtype=np.float32)
    if trimmed.ndim == 1:
        trimmed[:fade_n] *= fade_in
        trimmed[-fade_n:] *= fade_out
    else:
        trimmed[:, :fade_n] *= fade_in
        trimmed[:, -fade_n:] *= fade_out

    write_int16_wav(args.output, trimmed, sr)
    print(f"wrote: {args.output} ({trimmed.shape[-1]/sr:.3f}s, fade={args.fade_ms}ms)")


if __name__ == "__main__":
    main()
