#!/usr/bin/env python3
"""音声ファイルを EBU R128 (LUFS) で正規化する。WAV / MP3 対応。"""

from __future__ import annotations

import argparse
import math
import shutil
import subprocess
import tempfile
from pathlib import Path

import librosa
import numpy as np
import pyloudnorm as pyln
import soundfile as sf


def normalize(input_path: Path, output_path: Path, target_lufs: float):
    y, sr = librosa.load(str(input_path), sr=None, mono=False)
    is_stereo = y.ndim > 1
    y_meter = y.T if is_stereo else y

    meter = pyln.Meter(sr)
    current = meter.integrated_loudness(y_meter)
    if not math.isfinite(current):
        print(f"  {input_path.name}: silence, skip")
        return

    diff_db = target_lufs - current
    gain = 10.0 ** (diff_db / 20.0)
    y_normalized = y * gain

    # クリップ防止: peak が 0.99 を超えるなら追加ゲイン削減
    peak = float(np.max(np.abs(y_normalized)))
    if peak > 0.99:
        reduce = 0.99 / peak
        y_normalized *= reduce
        actual_lufs = current + 20 * math.log10(gain * reduce)
        print(f"  {input_path.name}: {current:.2f} → {actual_lufs:.2f} LUFS (clip-limited)")
    else:
        print(f"  {input_path.name}: {current:.2f} → {target_lufs:.2f} LUFS")

    output_path.parent.mkdir(parents=True, exist_ok=True)

    suffix = output_path.suffix.lower()
    if suffix == ".wav":
        # int16 PCM で書き出し
        pcm = (np.clip(y_normalized, -1.0, 1.0) * 32767.0).astype(np.int16)
        if is_stereo:
            pcm = pcm.T
        sf.write(str(output_path), pcm if is_stereo else pcm.reshape(-1, 1) if False else pcm, sr, subtype="PCM_16")
    elif suffix == ".mp3":
        # 一旦 WAV を tmp に書いて ffmpeg で MP3 化
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            tmp_wav = Path(tmp.name)
        try:
            pcm = (np.clip(y_normalized, -1.0, 1.0) * 32767.0).astype(np.int16)
            if is_stereo:
                pcm = pcm.T
            sf.write(str(tmp_wav), pcm, sr, subtype="PCM_16")
            subprocess.run([
                "ffmpeg", "-y", "-loglevel", "error",
                "-i", str(tmp_wav),
                "-codec:a", "libmp3lame", "-q:a", "2",  # VBR ~190 kbps
                str(output_path),
            ], check=True)
        finally:
            tmp_wav.unlink(missing_ok=True)
    else:
        raise ValueError(f"unsupported output extension: {suffix}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target-lufs", type=float, default=-18.0)
    parser.add_argument("inputs", nargs="+", type=Path)
    args = parser.parse_args()

    print(f"target: {args.target_lufs:.1f} LUFS\n")
    for path in args.inputs:
        normalize(path, path, args.target_lufs)


if __name__ == "__main__":
    main()
