#!/usr/bin/env bash
#
# 1024x1024 (以上) の PNG から macOS 用 .icns を生成する。
# 使い方: ./Scripts/make-icns.sh <input.png> <output.icns>
#
set -euo pipefail

INPUT="${1:?第1引数: 元 PNG パス}"
OUTPUT="${2:?第2引数: 出力 .icns パス}"

if [[ ! -f "${INPUT}" ]]; then
    echo "ERROR: 入力ファイルが見つかりません: ${INPUT}" >&2
    exit 1
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "${WORKDIR}"' EXIT

ICONSET="${WORKDIR}/AppIcon.iconset"
mkdir -p "${ICONSET}"

# macOS の標準サイズセット (各サイズ x 1x/2x)
declare -a SIZES=(16 32 128 256 512)
for size in "${SIZES[@]}"; do
    double=$((size * 2))
    sips -z "${size}" "${size}"  "${INPUT}" --out "${ICONSET}/icon_${size}x${size}.png"     >/dev/null
    sips -z "${double}" "${double}" "${INPUT}" --out "${ICONSET}/icon_${size}x${size}@2x.png" >/dev/null
done

mkdir -p "$(dirname "${OUTPUT}")"
iconutil -c icns "${ICONSET}" -o "${OUTPUT}"

echo "==> 生成完了: ${OUTPUT}"
