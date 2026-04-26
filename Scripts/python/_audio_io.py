"""音声 I/O の共通ヘルパ。"""

from __future__ import annotations

import os
import tempfile
from pathlib import Path

import numpy as np
from scipy.io import wavfile

INT16_MAX = 32767


def write_int16_wav(path: Path, samples: np.ndarray, sr: int) -> None:
    """float サンプル列を 16bit PCM WAV として原子的に書き出す。
    モノラル: shape=(N,) / ステレオ以上: shape=(channels, N) を期待。
    """
    pcm = (np.clip(samples, -1.0, 1.0) * INT16_MAX).astype(np.int16)
    if pcm.ndim > 1:
        pcm = pcm.T   # scipy 期待形式: (n_samples, n_channels)

    path.parent.mkdir(parents=True, exist_ok=True)
    # 一時ファイルに書いてから rename。書き込み中の中断でソースが壊れないように。
    with tempfile.NamedTemporaryFile(
        dir=path.parent, prefix=f".{path.name}.", suffix=".tmp", delete=False
    ) as tmp:
        tmp_path = Path(tmp.name)
    try:
        wavfile.write(str(tmp_path), sr, pcm)
        os.replace(tmp_path, path)
    except Exception:
        tmp_path.unlink(missing_ok=True)
        raise
