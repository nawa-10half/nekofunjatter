#!/usr/bin/env bash
#
# Nekofunjatter.app をビルドする。
# 出力: build/Nekofunjatter.app
#
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Nekofunjatter"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

CONFIG="${CONFIG:-release}"

echo "==> swift build (${CONFIG})"
swift build -c "${CONFIG}" --arch arm64 --arch x86_64

BIN_PATH=$(swift build -c "${CONFIG}" --arch arm64 --arch x86_64 --show-bin-path)
EXECUTABLE="${BIN_PATH}/${APP_NAME}"

if [[ ! -x "${EXECUTABLE}" ]]; then
    echo "ERROR: 実行ファイルが見つかりません: ${EXECUTABLE}" >&2
    exit 1
fi

echo "==> .app バンドルを作成: ${APP_BUNDLE}"
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${EXECUTABLE}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# .icns は Contents/Resources/AppIcon.icns に直接置く必要がある
# (CFBundleIconFile = "AppIcon" でこのパスから読まれる)
if [[ -f "Resources/Icons/AppIcon.icns" ]]; then
    cp "Resources/Icons/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

# Audio などのアセットをコピー
if [[ -d "Resources/Audio" ]]; then
    cp -R "Resources/Audio" "${APP_BUNDLE}/Contents/Resources/Audio"
fi
if [[ -d "Resources/Icons" ]]; then
    cp -R "Resources/Icons" "${APP_BUNDLE}/Contents/Resources/Icons"
fi

# PkgInfo (旧来の慣習)
printf 'APPL????' > "${APP_BUNDLE}/Contents/PkgInfo"

# 署名: .env で DEVELOPER_ID が指定されていれば Developer ID で署名する。
# Developer ID 署名なら macOS の TCC (Accessibility / Input Monitoring) が
# リビルド後も保持されるため、開発中の権限取り直しが不要になる。
if [[ -f .env ]]; then
    # shellcheck disable=SC1091
    source .env
fi
ENTITLEMENTS="Resources/Nekofunjatter.entitlements"
if [[ -n "${DEVELOPER_ID:-}" ]]; then
    echo "==> Developer ID 署名: ${DEVELOPER_ID}"
    codesign --force --options runtime \
        --entitlements "${ENTITLEMENTS}" \
        --sign "${DEVELOPER_ID}" \
        --timestamp=none \
        "${APP_BUNDLE}"
else
    echo "==> アドホック署名 (.env に DEVELOPER_ID が無いため)"
    codesign --force --sign - "${APP_BUNDLE}"
fi

echo "==> 完了: ${APP_BUNDLE}"
echo "    起動: open ${APP_BUNDLE}"
