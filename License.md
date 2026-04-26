# 楽曲・音源ライセンス

このリポジトリで利用する楽曲と音源ファイルのライセンスをまとめます。

---

## 楽曲: 「猫ふんじゃった」(原題: *Flohwalzer*)

作曲者不詳、19 世紀末の伝統曲。**パブリックドメイン**。
楽曲そのものを再生・編曲・配布することに著作権上の制約はありません。

---

## 音源ファイル

### `Resources/Audio/Neko_Funjatta.wav` (ピアノ録音)

- **出典**: [Wikimedia Commons - Der Flohwalzer.wav](https://commons.wikimedia.org/wiki/File:Der_Flohwalzer.wav)
- **作者**: Wikipedia ユーザー *Nunh-huh* による synth piano 演奏
- **ライセンス**: **CC0 1.0 Universal (Public Domain Dedication)**
  - 著作権者がすべての権利を放棄しパブリックドメインに供したもの
  - 商用・非商用、改変・再配布、いずれも自由
  - クレジット表記の義務なし (任意で記載することは推奨)

### `Resources/Audio/Neko_Funjatta_8bit.wav` (8bit 風アレンジ)

`Neko_Funjatta.wav` を [librosa](https://librosa.org/) でピッチ抽出し、矩形波で再合成した派生作品。
原曲が CC0 のため、**この派生作品も実質的に CC0** として扱えます。

ローカルで再生成する場合：

```bash
Scripts/python/.venv/bin/python Scripts/python/extract_melody.py \
    --input Resources/Audio/Neko_Funjatta.wav \
    --json-output Resources/Generated/melody.json \
    --wav-output Resources/Audio/Neko_Funjatta_8bit.wav
```

### `Resources/Audio/neko_Dubstep.mp3` (ダブステップ風)

生成 AI を用いて作成。著作権は **本リポジトリの作者 (nawa-10half) に全て帰属**。
本アプリのソースコードのライセンスに準じて再配布可能。

---

## 第三者ソフトウェアライセンス

8bit 音源生成スクリプトは以下の OSS に依存します (アプリ本体には含まれません)。

| パッケージ | ライセンス | 用途 |
|---|---|---|
| [librosa](https://librosa.org/) | ISC | ピッチ抽出 (`extract_melody.py`) |
| [NumPy](https://numpy.org/) | BSD-3-Clause | 数値演算 |
| [SciPy](https://scipy.org/) | BSD-3-Clause | WAV 入出力 |
| [cairosvg](https://cairosvg.org/) | LGPL-3.0 | SVG → PDF (`svg_to_pdf.py`) |
