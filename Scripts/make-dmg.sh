#!/usr/bin/env bash
#
# 公証済み .app から配布用 .dmg を作る。
# create-dmg があればそれを使い、無ければ hdiutil で簡易作成。
#
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Nekofunjatter"
APP_BUNDLE="build/${APP_NAME}.app"
DMG_PATH="build/${APP_NAME}.dmg"

if [[ ! -d "${APP_BUNDLE}" ]]; then
    echo "ERROR: ${APP_BUNDLE} が見つかりません" >&2
    exit 1
fi

rm -f "${DMG_PATH}"

if command -v create-dmg >/dev/null 2>&1; then
    echo "==> create-dmg で作成"
    create-dmg \
        --volname "${APP_NAME}" \
        --window-size 480 320 \
        --icon-size 96 \
        --icon "${APP_NAME}.app" 120 160 \
        --app-drop-link 360 160 \
        "${DMG_PATH}" \
        "${APP_BUNDLE}"
else
    echo "==> create-dmg 未導入。hdiutil で簡易作成 (brew install create-dmg 推奨)"
    STAGING="build/dmg-staging"
    rm -rf "${STAGING}"
    mkdir -p "${STAGING}"
    cp -R "${APP_BUNDLE}" "${STAGING}/"
    ln -s /Applications "${STAGING}/Applications"
    hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGING}" -ov -format UDZO "${DMG_PATH}"
    rm -rf "${STAGING}"
fi

echo "==> 完了: ${DMG_PATH}"
