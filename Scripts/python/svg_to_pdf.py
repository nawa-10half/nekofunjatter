#!/usr/bin/env python3
"""SVG → PDF 変換 (cairosvg ラッパー)。"""

import argparse
from pathlib import Path
import cairosvg


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    args.output.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2pdf(url=str(args.input), write_to=str(args.output))
    print(f"wrote: {args.output}")


if __name__ == "__main__":
    main()
