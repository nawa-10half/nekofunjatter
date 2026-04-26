# 楽曲・音源ライセンス

このリポジトリに含まれる楽曲と音源ファイルのライセンスについて記載します。

---

## 楽曲: 「猫ふんじゃった」(原題: *Flohwalzer*)

作曲者不詳、19 世紀末の伝統曲。作曲・編曲権はすでに切れており **パブリックドメイン** です。

楽曲そのものを再生・編曲・配布することに制約はありません。
ただし、**個別の演奏録音には別途著作隣接権 (実演家・レコード製作者の権利) が発生します**。
以下、本リポジトリ同梱の音源ファイルごとにライセンスを記載します。

---

## 音源ファイル

### `Resources/Audio/Neko_Funjatta.wav`

> **TODO: 出典・ライセンスを記載してください**
>
> 例:
> - 自身で演奏・録音 → "© <year> <name>. All rights reserved." または CC ライセンス
> - フリー素材サイト → 出典 URL と利用規約のリンク
> - 商用ライブラリ → ライセンス保持者と利用範囲

### `Resources/Audio/Neko_Funjatta_8bit.wav`

`Neko_Funjatta.wav` を Python ([librosa](https://librosa.org/)) でピッチ抽出し、
矩形波で再合成した **派生作品** (derivative work)。
元音源と同じライセンスが適用されます。

### `Resources/Audio/neko_Dubstep.mp3`

> **TODO: 出典・ライセンスを記載してください**

---

## 第三者ソフトウェアライセンス

8bit 音源生成スクリプトは以下の OSS に依存します (アプリ本体には含まれません)。

| パッケージ | ライセンス | 用途 |
|---|---|---|
| [librosa](https://librosa.org/) | ISC | ピッチ抽出 (`extract_melody.py`) |
| [NumPy](https://numpy.org/) | BSD-3-Clause | 数値演算 |
| [SciPy](https://scipy.org/) | BSD-3-Clause | WAV 入出力 |
| [cairosvg](https://cairosvg.org/) | LGPL-3.0 | SVG → PDF (`svg_to_pdf.py`) |
