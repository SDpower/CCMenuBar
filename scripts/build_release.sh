#!/bin/bash
# 自動建置 CCMenuBar Release 並打包為 DMG
# 輸出兩個檔案：
#   CCMenuBar-arm64.dmg   (Apple Silicon)
#   CCMenuBar-x86_64.dmg  (Intel)

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$PROJECT_DIR/CCMenuBar.xcodeproj"
SCHEME="CCMenuBar"
BUILD_DIR="/tmp/CCMenuBar_release"
OUTPUT_DIR="$PROJECT_DIR/release"

echo "=== CCMenuBar Release Build ==="
echo "專案：$PROJECT"
echo "輸出：$OUTPUT_DIR"
echo ""

mkdir -p "$OUTPUT_DIR"

build_and_package() {
    local ARCH="$1"
    local APP_NAME="CCMenuBar"
    local DERIVED="$BUILD_DIR/$ARCH"
    local APP_PATH="$DERIVED/Build/Products/Release/$APP_NAME.app"
    local DMG_PATH="$OUTPUT_DIR/$APP_NAME-$ARCH.dmg"
    local STAGING="/tmp/${APP_NAME}_staging_$ARCH"

    echo ">>> 建置 $ARCH ..."
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration Release \
        -derivedDataPath "$DERIVED" \
        ARCHS="$ARCH" \
        ONLY_ACTIVE_ARCH=NO \
        clean build \
        2>&1 | grep -E "^(Build|error:|warning:|\\*\\*)"

    echo ">>> 打包 $ARCH → $DMG_PATH"
    rm -rf "$STAGING"
    mkdir -p "$STAGING"
    cp -R "$APP_PATH" "$STAGING/"

    # 建立 Applications 捷徑
    ln -s /Applications "$STAGING/Applications"

    # 移除舊 DMG
    rm -f "$DMG_PATH"

    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$STAGING" \
        -ov \
        -format UDZO \
        "$DMG_PATH"

    rm -rf "$STAGING"
    echo ">>> 完成：$DMG_PATH"
    echo ""
}

build_and_package "arm64"
build_and_package "x86_64"

echo "=== 全部完成 ==="
ls -lh "$OUTPUT_DIR"/*.dmg

open "$OUTPUT_DIR"
