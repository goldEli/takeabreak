#!/bin/zsh

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
APP_NAME="TakeABreak"
BUILD_DIR="$ROOT_DIR/.build/app"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
EXECUTABLE_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
INFO_PLIST_PATH="$APP_DIR/Contents/Info.plist"
SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
MODULE_CACHE_DIR="$BUILD_DIR/module-cache"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
ICON_SOURCE_PATH="$ICONSET_DIR/icon_512x512@2x.png"
ICON_PATH="$RESOURCES_DIR/AppIcon.png"

mkdir -p "$EXECUTABLE_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$MODULE_CACHE_DIR"
cp "$ROOT_DIR/App/Info.plist" "$INFO_PLIST_PATH"

swift -module-cache-path "$MODULE_CACHE_DIR" "$ROOT_DIR/scripts/generate_icon.swift" "$ICONSET_DIR"
cp "$ICON_SOURCE_PATH" "$ICON_PATH"

swiftc \
  -sdk "$SDK_PATH" \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -parse-as-library \
  -framework AppKit \
  -framework SwiftUI \
  -framework Combine \
  -framework UserNotifications \
  "$ROOT_DIR"/Sources/takeabreak/*.swift \
  -o "$EXECUTABLE_DIR/$APP_NAME"

swift -module-cache-path "$MODULE_CACHE_DIR" "$ROOT_DIR/scripts/set_bundle_icon.swift" "$APP_DIR" "$ICON_PATH"

echo "Built app bundle at: $APP_DIR"
