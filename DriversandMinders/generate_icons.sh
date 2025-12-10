#!/bin/bash

# Generate app icons from SVG source for Drivers & Busminders App
# Uses rsvg-convert to create PNG files at various sizes

SOURCE_SVG="app_icon_source.svg"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Generating Drivers & Busminders app icons from $SOURCE_SVG..."
echo "================================================"

# Function to generate icon
generate_icon() {
    local output_path="$1"
    local size="$2"

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output_path")"

    # Generate PNG
    rsvg-convert -w "$size" -h "$size" "$SOURCE_SVG" > "$output_path"

    if [ $? -eq 0 ]; then
        echo "✓ Generated $output_path (${size}x${size})"
    else
        echo "✗ Failed to generate $output_path"
        return 1
    fi
}

# iOS Icons
echo ""
echo "Generating iOS icons..."
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png" 20
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png" 40
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png" 60
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png" 29
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png" 58
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png" 87
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png" 40
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png" 80
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png" 120
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png" 120
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png" 180
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png" 76
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png" 152
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png" 167
generate_icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" 1024

# Android Icons
echo ""
echo "Generating Android icons..."
generate_icon "android/app/src/main/res/mipmap-mdpi/ic_launcher.png" 48
generate_icon "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" 72
generate_icon "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png" 96
generate_icon "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png" 144
generate_icon "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" 192

# macOS Icons
echo ""
echo "Generating macOS icons..."
generate_icon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png" 16
generate_icon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png" 32
generate_icon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png" 64
generate_icon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png" 128
generate_icon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png" 256
generate_icon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png" 512
generate_icon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png" 1024

# Generate preview image
echo ""
echo "Generating preview image..."
generate_icon "app_icon_preview.png" 512

echo ""
echo "================================================"
echo "✅ Icon generation complete!"
echo ""
echo "Preview: app_icon_preview.png"
echo ""
echo "Icons have been generated for:"
echo "  • iOS (15 sizes)"
echo "  • Android (5 densities)"
echo "  • macOS (7 sizes)"
echo ""
echo "Drivers & Busminders App - Steering Wheel Icon"
