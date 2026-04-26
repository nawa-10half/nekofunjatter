#!/usr/bin/env python3
"""WAV の前後の無音をトリムし、ループ用の極短フェードを付ける。"""

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
    parser.add_argument("--top-db", type=float, default=30.0,
                        help="無音判定の閾値 (dB)。低いほど厳しく無音判定 (= 多く残す)")
    parser.add_argument("--fade-ms", type=float, default=8.0,
                        help="ループ時のクリック防止フェード (ms)")
    args = parser.parse_args()

    y, sr = librosa.load(str(args.input), sr=None, mono=False)
    print(f"loaded: {args.input.name}, sr={sr}, original={(y.shape[-1])/sr:.3f}s")

    # 無音検出はモノラル基準で実施
    if y.ndim == 1:
        y_mono = y
    else:
        y_mono = np.mean(y, axis=0)

    _, idx = librosa.effects.trim(y_mono, top_db=args.top_db)
    start, end = idx[0], idx[1]
    if y.ndim == 1:
        trimmed = y[start:end]
    else:
        trimmed = y[:, start:end]

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

    pcm = (np.clip(trimmed, -1.0, 1.0) * 32767.0).astype(np.int16)
    if pcm.ndim > 1:
        pcm = pcm.T   # scipy 期待形式: (n_samples, n_channels)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    wavfile.write(str(args.output), sr, pcm)
    print(f"wrote: {args.output} ({trimmed.shape[-1]/sr:.3f}s, fade={args.fade_ms}ms)")


if __name__ == "__main__":
    main()
