#!/usr/bin/env bash
#
# Nekofunjatter.app を Developer ID で署名し、公証 (notarize) して staple する。
#
# 必要な環境変数 (.env を読み込む):
#   DEVELOPER_ID        : "Developer ID Application: Your Name (TEAMID)"
#   APPLE_ID            : Apple ID (公証アカウント)
#   APPLE_TEAM_ID       : チーム ID
#   APPLE_APP_PASSWORD  : アプリ専用パスワード (https://appleid.apple.com/)
#
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f .env ]]; then
    # shellcheck disable=SC1091
    source .env
fi

: "${DEVELOPER_ID:?DEVELOPER_ID が未設定}"
: "${APPLE_ID:?APPLE_ID が未設定}"
: "${APPLE_TEAM_ID:?APPLE_TEAM_ID が未設定}"
: "${APPLE_APP_PASSWORD:?APPLE_APP_PASSWORD が未設定}"

APP_NAME="Nekofunjatter"
APP_BUNDLE="build/${APP_NAME}.app"
ENTITLEMENTS="Resources/${APP_NAME}.entitlements"
ZIP_PATH="build/${APP_NAME}.zip"

if [[ ! -d "${APP_BUNDLE}" ]]; then
    echo "==> ${APP_BUNDLE} が無いので build-app.sh を実行"
    Scripts/build-app.sh
fi

echo "==> codesign"
codesign --force --deep --options runtime \
    --entitlements "${ENTITLEMENTS}" \
    --sign "${DEVELOPER_ID}" \
    --timestamp \
    "${APP_BUNDLE}"

echo "==> 署名検証"
codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}"

echo "==> 公証用 zip を作成"
rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"

echo "==> notarytool submit (--wait)"
xcrun notarytool submit "${ZIP_PATH}" \
    --apple-id "${APPLE_ID}" \
    --team-id "${APPLE_TEAM_ID}" \
    --password "${APPLE_APP_PASSWORD}" \
    --wait

echo "==> stapler"
xcrun stapler staple "${APP_BUNDLE}"
xcrun stapler validate "${APP_BUNDLE}"

echo "==> 完了"
