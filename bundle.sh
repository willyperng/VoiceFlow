#!/bin/bash
set -euo pipefail

APP_NAME="VoiceFlow"
BUNDLE_DIR="${APP_NAME}.app"
BUILD_CONFIG="release"

echo "==> Building ${APP_NAME} (${BUILD_CONFIG})..."
swift build -c "${BUILD_CONFIG}"

echo "==> Creating app bundle..."
rm -rf "${BUNDLE_DIR}"

mkdir -p "${BUNDLE_DIR}/Contents/MacOS"
mkdir -p "${BUNDLE_DIR}/Contents/Resources"

cp ".build/${BUILD_CONFIG}/${APP_NAME}" "${BUNDLE_DIR}/Contents/MacOS/${APP_NAME}"
cp Info.plist "${BUNDLE_DIR}/Contents/"

if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${BUNDLE_DIR}/Contents/Resources/"
fi

echo "==> Ad-hoc code signing..."
codesign --force --deep --sign - "${BUNDLE_DIR}"

echo "==> Done. Bundle created at: ${BUNDLE_DIR}"
echo ""
echo "To install:"
echo "  cp -R ${BUNDLE_DIR} /Applications/"
echo ""
echo "To add to Login Items:"
echo "  System Settings > General > Login Items > '+' > select VoiceFlow"
