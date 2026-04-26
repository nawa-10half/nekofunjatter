#!/usr/bin/env python3
"""melody.json から 8bit 風 WAV を合成する (extract をスキップ)。
手動で JSON を編集した後の再生成に使う。"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from _chiptune import render_chiptune


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--json-input", type=Path, required=True)
    parser.add_argument("--wav-output", type=Path, required=True)
    args = parser.parse_args()

    with args.json_input.open() as f:
        data = json.load(f)

    events = data["events"]
    note_count = sum(1 for e in events if e["midi"] >= 0)
    print(f"loaded {len(events)} events ({note_count} notes) from {args.json_input}")

    args.wav_output.parent.mkdir(parents=True, exist_ok=True)
    render_chiptune(events, args.wav_output)


if __name__ == "__main__":
    main()
