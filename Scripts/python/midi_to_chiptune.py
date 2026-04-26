#!/usr/bin/env python3
"""MIDI ファイルを _chiptune.py の矩形波シンセでレンダリングする。

events 形式 ({"midi", "start_sec", "duration_sec"}) に変換してから
render_chiptune に渡す。多声は加算合成 (clip 処理あり)。
"""

from __future__ import annotations

import argparse
from pathlib import Path

import mido

from _chiptune import render_chiptune


def keep_top_line(events: list[dict]) -> list[dict]:
    """重なるノートのうち最高音だけ残し、単旋律化する (greedy)。"""
    sorted_events = sorted(events, key=lambda e: e["start_sec"])
    result: list[dict] = []
    for ev in sorted_events:
        start = ev["start_sec"]
        end = start + ev["duration_sec"]
        if result:
            prev = result[-1]
            prev_end = prev["start_sec"] + prev["duration_sec"]
            if start < prev_end:
                if ev["midi"] > prev["midi"]:
                    # 高い音が来たら前を打ち切って差し替え
                    prev["duration_sec"] = max(0.001, start - prev["start_sec"])
                    result.append(dict(ev))
                elif end > prev_end:
                    # 低い音は隠れる部分を捨て、前が終わった後の続きだけ残す
                    result.append({
                        "midi": ev["midi"],
                        "start_sec": prev_end,
                        "duration_sec": end - prev_end,
                    })
                # 完全に隠れる場合は捨てる
                continue
        result.append(dict(ev))
    return result


def midi_to_events(midi_path: Path) -> list[dict]:
    mid = mido.MidiFile(midi_path)

    active: dict[int, float] = {}  # pitch -> start_sec
    events: list[dict] = []
    abs_time = 0.0

    # MidiFile を iterate すると tempo 込みで秒換算された delta が msg.time に入る
    for msg in mid:
        abs_time += msg.time
        if msg.type == "note_on" and msg.velocity > 0:
            active[msg.note] = abs_time
        elif msg.type == "note_off" or (msg.type == "note_on" and msg.velocity == 0):
            start = active.pop(msg.note, None)
            if start is not None:
                duration = abs_time - start
                if duration > 0:
                    events.append({
                        "midi": msg.note,
                        "start_sec": start,
                        "duration_sec": duration,
                    })

    # 終端で note_off が来なかったぶんを救済
    for note, start in active.items():
        duration = abs_time - start
        if duration > 0:
            events.append({
                "midi": note,
                "start_sec": start,
                "duration_sec": duration,
            })

    events.sort(key=lambda e: e["start_sec"])
    return events


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--amplitude", type=float, default=0.25,
                        help="ノート単体の振幅 (多声でクリップする場合は下げる)")
    parser.add_argument("--duty", type=float, default=0.5,
                        help="矩形波 duty cycle (0.125 / 0.25 / 0.5 で NES 系)")
    parser.add_argument("--quantize", type=int, default=127,
                        help="量子化段数。小さくすると粗い 8bit っぽさが増す")
    parser.add_argument("--monophonic", action="store_true",
                        help="同時発音のうち最高音のみ残し単旋律化する")
    args = parser.parse_args()

    events = midi_to_events(args.input)
    if args.monophonic:
        events = keep_top_line(events)
    print(f"events: {len(events)}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    render_chiptune(
        events,
        args.output,
        amplitude=args.amplitude,
        duty=args.duty,
        quantize_levels=args.quantize,
    )


if __name__ == "__main__":
    main()
