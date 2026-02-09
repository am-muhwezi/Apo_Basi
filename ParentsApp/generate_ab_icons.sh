#!/bin/bash
# Generate app icons from AB logo using ImageMagick

LOGO_PATH="assets/images/AB_logo.jpg"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

if [ ! -f "$LOGO_PATH" ]; then
    echo "❌ Error: Logo file not found at $LOGO_PATH"
    exit 1
fi

echo "Generating app icons from AB logo..."
echo "Using logo: $LOGO_PATH"
echo ""

# Android icons
echo "Generating Android icons..."
convert "$LOGO_PATH" -resize 48x48 "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
echo "✓ Generated mipmap-mdpi/ic_launcher.png (48x48)"

convert "$LOGO_PATH" -resize 72x72 "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
echo "✓ Generated mipmap-hdpi/ic_launcher.png (72x72)"

convert "$LOGO_PATH" -resize 96x96 "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
echo "✓ Generated mipmap-xhdpi/ic_launcher.png (96x96)"

convert "$LOGO_PATH" -resize 144x144 "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
echo "✓ Generated mipmap-xxhdpi/ic_launcher.png (144x144)"

convert "$LOGO_PATH" -resize 192x192 "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
echo "✓ Generated mipmap-xxxhdpi/ic_launcher.png (192x192)"

# iOS icons (if ios directory exists)
if [ -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
    echo ""
    echo "Generating iOS icons..."

    mkdir -p "ios/Runner/Assets.xcassets/AppIcon.appiconset"

    convert "$LOGO_PATH" -resize 20x20 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"
    convert "$LOGO_PATH" -resize 40x40 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"
    convert "$LOGO_PATH" -resize 60x60 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png"
    convert "$LOGO_PATH" -resize 29x29 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"
    convert "$LOGO_PATH" -resize 58x58 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"
    convert "$LOGO_PATH" -resize 87x87 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png"
    convert "$LOGO_PATH" -resize 40x40 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"
    convert "$LOGO_PATH" -resize 80x80 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"
    convert "$LOGO_PATH" -resize 120x120 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png"
    convert "$LOGO_PATH" -resize 120x120 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"
    convert "$LOGO_PATH" -resize 180x180 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"
    convert "$LOGO_PATH" -resize 76x76 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"
    convert "$LOGO_PATH" -resize 152x152 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"
    convert "$LOGO_PATH" -resize 167x167 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"
    convert "$LOGO_PATH" -resize 1024x1024 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"

    echo "✓ Generated iOS icons"
fi

# macOS icons (if macos directory exists)
if [ -d "macos/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
    echo ""
    echo "Generating macOS icons..."

    mkdir -p "macos/Runner/Assets.xcassets/AppIcon.appiconset"

    convert "$LOGO_PATH" -resize 16x16 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png"
    convert "$LOGO_PATH" -resize 32x32 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png"
    convert "$LOGO_PATH" -resize 64x64 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png"
    convert "$LOGO_PATH" -resize 128x128 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png"
    convert "$LOGO_PATH" -resize 256x256 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png"
    convert "$LOGO_PATH" -resize 512x512 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png"
    convert "$LOGO_PATH" -resize 1024x1024 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png"

    echo "✓ Generated macOS icons"
fi

# Preview image
echo ""
echo "Generating preview image..."
convert "$LOGO_PATH" -resize 512x512 "app_icon_preview.png"
echo "✓ Generated app_icon_preview.png (512x512)"

echo ""
echo "✅ All icons generated successfully!"
echo ""
echo "Preview: app_icon_preview.png"
echo "The icons have been placed in their respective platform directories."
