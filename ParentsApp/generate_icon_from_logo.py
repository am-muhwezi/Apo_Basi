#!/usr/bin/env python3
"""
Generate app icons from AB logo for the Parents School Bus Tracking App
Takes the AB_logo.jpg and creates icons in various sizes for iOS, Android, and other platforms
"""

from PIL import Image
import os

def create_icon_from_logo(logo_path, size):
    """Create a single app icon at the specified size from the logo"""
    # Open the logo
    logo = Image.open(logo_path)

    # Convert to RGBA if not already
    if logo.mode != 'RGBA':
        logo = logo.convert('RGBA')

    # Resize to target size with high-quality resampling
    icon = logo.resize((size, size), Image.Resampling.LANCZOS)

    return icon

def main():
    """Generate all required icon sizes from AB logo"""

    # Define icon sizes for different platforms
    icon_configs = {
        # iOS
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png': 167,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png': 1024,

        # Android
        'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
        'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
        'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,

        # macOS
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png': 16,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png': 32,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png': 64,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png': 128,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png': 256,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png': 512,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png': 1024,
    }

    print("Generating app icons from AB logo...")
    print(f"Total icons to generate: {len(icon_configs)}")

    # Get the script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    logo_path = os.path.join(script_dir, 'assets/images/AB_logo.jpg')

    if not os.path.exists(logo_path):
        print(f"❌ Error: Logo file not found at {logo_path}")
        return

    print(f"Using logo: {logo_path}")

    for path, size in icon_configs.items():
        full_path = os.path.join(script_dir, path)

        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(full_path), exist_ok=True)

        # Create icon
        icon = create_icon_from_logo(logo_path, size)

        # Save with maximum quality
        icon.save(full_path, 'PNG', optimize=True)
        print(f"✓ Generated {path} ({size}x{size})")

    # Also generate a Windows .ico file
    print("\nGenerating Windows .ico file...")
    ico_sizes = [16, 32, 48, 64, 128, 256]
    ico_images = [create_icon_from_logo(logo_path, size) for size in ico_sizes]
    ico_path = os.path.join(script_dir, 'windows/runner/resources/app_icon.ico')
    os.makedirs(os.path.dirname(ico_path), exist_ok=True)
    ico_images[0].save(ico_path, format='ICO', sizes=[(s, s) for s in ico_sizes])
    print(f"✓ Generated windows/runner/resources/app_icon.ico")

    # Generate a preview image
    print("\nGenerating preview image...")
    preview = create_icon_from_logo(logo_path, 512)
    preview_path = os.path.join(script_dir, 'app_icon_preview.png')
    preview.save(preview_path, 'PNG', optimize=True)
    print(f"✓ Generated app_icon_preview.png (512x512)")

    print("\n✅ All icons generated successfully!")
    print("\nPreview: app_icon_preview.png")
    print("The icons have been placed in their respective platform directories.")

if __name__ == '__main__':
    main()
