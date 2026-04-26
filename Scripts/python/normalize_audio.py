#!/usr/bin/env python3
"""音声ファイルを EBU R128 (LUFS) で正規化する。WAV / MP3 対応。"""

from __future__ import annotations

import argparse
import math
import os
import subprocess
import tempfile
from pathlib import Path

import librosa
import numpy as np
import pyloudnorm as pyln

from _audio_io import write_int16_wav


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

    suffix = output_path.suffix.lower()
    if suffix == ".wav":
        write_int16_wav(output_path, y_normalized, sr)
    elif suffix == ".mp3":
        # 一旦 WAV を tmp に書いて ffmpeg で MP3 化、最終的に atomic に差し替え
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_wav_f:
            tmp_wav = Path(tmp_wav_f.name)
        with tempfile.NamedTemporaryFile(
            dir=output_path.parent, prefix=f".{output_path.name}.", suffix=".tmp", delete=False
        ) as tmp_mp3_f:
            tmp_mp3 = Path(tmp_mp3_f.name)
        try:
            write_int16_wav(tmp_wav, y_normalized, sr)
            subprocess.run([
                "ffmpeg", "-y", "-loglevel", "error",
                "-i", str(tmp_wav),
                "-codec:a", "libmp3lame", "-q:a", "2",  # VBR ~190 kbps
                str(tmp_mp3),
            ], check=True)
            os.replace(tmp_mp3, output_path)
        except Exception:
            tmp_mp3.unlink(missing_ok=True)
            raise
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
