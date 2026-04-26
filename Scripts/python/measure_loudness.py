#!/usr/bin/env python3
"""音声ファイルの統合ラウドネス (EBU R128 LUFS) を測定する。
ターゲット LUFS との差分から、Swift 側で適用する volume 倍率を計算して表示する。"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

import librosa
import numpy as np
import pyloudnorm as pyln


def measure(path: Path) -> tuple[float, float]:
    """(LUFS, peak) を返す。"""
    y, sr = librosa.load(str(path), sr=None, mono=False)
    if y.ndim == 1:
        y_meter = y
    else:
        y_meter = y.T  # pyln 期待形式: (n_samples, n_channels)
    meter = pyln.Meter(sr)
    lufs = meter.integrated_loudness(y_meter)
    peak = float(np.max(np.abs(y)))
    return lufs, peak


def linear_gain(current_lufs: float, target_lufs: float) -> float:
    """LUFS 差分から線形倍率に変換 (10^(diff_dB/20))。"""
    diff_db = target_lufs - current_lufs
    return 10.0 ** (diff_db / 20.0)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target-lufs", type=float, default=-18.0)
    parser.add_argument("inputs", nargs="+", type=Path)
    args = parser.parse_args()

    print(f"target: {args.target_lufs:.1f} LUFS\n")
    print(f"{'file':<35} {'LUFS':>8} {'peak':>8} {'volume':>10}  {'true peak after':>18}")
    print("-" * 90)
    for path in args.inputs:
        try:
            lufs, peak = measure(path)
        except Exception as e:
            print(f"{path.name:<35}  ERROR: {e}")
            continue
        if not math.isfinite(lufs):
            print(f"{path.name:<35} {'-inf':>8} {peak:>8.3f}  (silence?)")
            continue
        gain = linear_gain(lufs, args.target_lufs)
        # クリップ防止: peak * gain が 1.0 を超えないように制限
        max_gain = 0.99 / peak if peak > 0 else gain
        safe_gain = min(gain, max_gain)
        post_peak = peak * safe_gain
        clipped = " (clipped)" if safe_gain < gain else ""
        print(f"{path.name:<35} {lufs:>8.2f} {peak:>8.3f} {safe_gain:>10.4f}  {post_peak:>18.3f}{clipped}")


if __name__ == "__main__":
    main()
