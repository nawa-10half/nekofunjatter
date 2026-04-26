#!/usr/bin/env python3
"""GitHub repository Social Preview 用画像 (1280x640) を生成する。

中央右にアプリアイコン、左に大きめのタイトル + 説明。
背景はアイコンの淡いクリーム色に合わせる。
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


CANVAS_W, CANVAS_H = 1280, 640
BG_COLOR = (249, 244, 232)   # アイコン背景に近い淡いクリーム
TEXT_COLOR = (40, 40, 40)
SUBTITLE_COLOR = (110, 110, 110)


def find_font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    """macOS 標準フォントを優先的に探す。"""
    candidates_bold = [
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/SFNS.ttf",
    ]
    candidates = [
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SFNS.ttf",
    ]
    for p in (candidates_bold if bold else candidates):
        if Path(p).exists():
            try:
                if bold:
                    return ImageFont.truetype(p, size, index=1)  # Bold variant
                return ImageFont.truetype(p, size)
            except (OSError, IndexError):
                pass
    return ImageFont.load_default()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--icon", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    canvas = Image.new("RGB", (CANVAS_W, CANVAS_H), BG_COLOR)

    # 右側にアイコン (520x520) を配置
    icon = Image.open(args.icon).convert("RGBA")
    icon_size = 520
    icon = icon.resize((icon_size, icon_size), Image.LANCZOS)
    icon_x = CANVAS_W - icon_size - 60
    icon_y = (CANVAS_H - icon_size) // 2
    canvas.paste(icon, (icon_x, icon_y), icon)

    # 左側にテキスト
    draw = ImageDraw.Draw(canvas)

    title = "Nekofunjatter"
    subtitle = "Plays \"Flohwalzer\" when a cat"
    subtitle2 = "steps on your keyboard."

    title_font = find_font(96, bold=True)
    subtitle_font = find_font(36)

    text_x = 60
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_h = title_bbox[3] - title_bbox[1]

    title_y = (CANVAS_H - title_h - 100) // 2
    draw.text((text_x, title_y), title, fill=TEXT_COLOR, font=title_font)
    draw.text((text_x, title_y + title_h + 20), subtitle, fill=SUBTITLE_COLOR, font=subtitle_font)
    draw.text((text_x, title_y + title_h + 70), subtitle2, fill=SUBTITLE_COLOR, font=subtitle_font)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(str(args.output), "PNG", optimize=True)
    print(f"wrote: {args.output} ({CANVAS_W}x{CANVAS_H})")


if __name__ == "__main__":
    main()
