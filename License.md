# 楽曲・音源ライセンス

このリポジトリで利用する楽曲と音源ファイルのライセンスをまとめます。

---

## 楽曲: 「猫ふんじゃった」(原題: *Flohwalzer*)

作曲者不詳、19 世紀末の伝統曲。**パブリックドメイン**。
楽曲そのものを再生・編曲・配布することに著作権上の制約はありません。

ただし **個別の演奏録音には別途著作隣接権** (実演家・レコード製作者の権利) が発生するため、以下、本リポジトリで利用する音源ファイルごとにライセンスを明記します。

---

## 音源ファイル

### `Neko_Funjatta.wav` (ピアノ録音)

- **出典**: [SoundJewel — 猫ふんじゃった](https://soundjewel.symphie.jp/gekiban/neko_funjatta)
- **ライセンス概要** ([詳細はサイト規約](https://soundjewel.symphie.jp/gekiban/neko_funjatta) を参照):

| 項目 | 可否 |
|---|---|
| ダウンロード・利用 | 無料 |
| 商用利用 | ○ |
| 使用期間・使用回数の制限 | なし |
| 使用許諾の申請・利用報告 | 必要なし |
| クレジット表記 | 必要なし |
| 編集・エフェクト付加 | ○ |
| 映画 / TV / ラジオ / CM / WEB / YouTube / ゲーム / アプリ / 演奏 等での利用 | ○ |
| **販売・再配布** | **✕** |

> ⚠️ **本リポジトリには `Neko_Funjatta.wav` を同梱しません。**
> ご自身で [SoundJewel](https://soundjewel.symphie.jp/gekiban/neko_funjatta) からダウンロードし、
> `Resources/Audio/Neko_Funjatta.wav` に配置してください。

### `Neko_Funjatta_8bit.wav` (8bit 風アレンジ)

`Neko_Funjatta.wav` を [librosa](https://librosa.org/) でピッチ抽出し、矩形波で再合成した派生作品 (derivative work)。SoundJewel の規約「販売・配布 ✕」が派生物にも適用されるため、本リポジトリには **同梱しません**。

ローカルで生成するには：

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
