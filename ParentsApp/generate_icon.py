#!/usr/bin/env python3
"""
Generate app icons for the Parents School Bus Tracking App
Creates icons in various sizes for iOS, Android, and other platforms
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_icon(size):
    """Create a single app icon at the specified size"""
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Calculate scaling factor
    scale = size / 1024

    # Background circle with warm color
    padding = int(80 * scale)
    bg_color = (255, 248, 225, 255)  # Warm beige background
    draw.ellipse([padding, padding, size-padding, size-padding], fill=bg_color)

    # Main circle background (amber)
    main_padding = int(100 * scale)
    main_color = (255, 193, 7, 255)  # Amber color
    draw.ellipse([main_padding, main_padding, size-main_padding, size-main_padding],
                 fill=main_color)

    # Bus body - simplified for icon
    bus_top = int(size * 0.35)
    bus_bottom = int(size * 0.7)
    bus_left = int(size * 0.25)
    bus_right = int(size * 0.75)
    bus_color = (255, 160, 0, 255)  # Orange
    corner_radius = int(20 * scale)

    # Draw rounded rectangle for bus body
    draw.rounded_rectangle(
        [bus_left, bus_top, bus_right, bus_bottom],
        radius=corner_radius,
        fill=bus_color
    )

    # Bus roof (trapezoid approximation with rectangle)
    roof_height = int(40 * scale)
    roof_color = (255, 179, 0, 255)
    roof_inset = int(15 * scale)
    draw.polygon([
        (bus_left + roof_inset, bus_top),
        (bus_left, bus_top + roof_height),
        (bus_right, bus_top + roof_height),
        (bus_right - roof_inset, bus_top)
    ], fill=roof_color)

    # Windows - 3 windows
    window_color = (77, 208, 225, 255)  # Cyan
    window_margin = int(30 * scale)
    window_top = bus_top + int(50 * scale)
    window_height = int(60 * scale)
    window_width = int(60 * scale)
    window_spacing = int(20 * scale)

    total_window_width = window_width * 3 + window_spacing * 2
    first_window_left = (size - total_window_width) // 2

    for i in range(3):
        wx = first_window_left + i * (window_width + window_spacing)
        draw.rounded_rectangle(
            [wx, window_top, wx + window_width, window_top + window_height],
            radius=int(5 * scale),
            fill=window_color,
            outline=(255, 143, 0, 255),
            width=int(3 * scale)
        )

    # Wheels
    wheel_y = bus_bottom + int(15 * scale)
    wheel_radius = int(35 * scale)
    wheel_color = (38, 50, 56, 255)  # Dark gray
    wheel_inner_color = (66, 66, 66, 255)

    # Left wheel
    wheel1_x = bus_left + int(70 * scale)
    draw.ellipse(
        [wheel1_x - wheel_radius, wheel_y - wheel_radius,
         wheel1_x + wheel_radius, wheel_y + wheel_radius],
        fill=wheel_color
    )
    draw.ellipse(
        [wheel1_x - wheel_radius//2, wheel_y - wheel_radius//2,
         wheel1_x + wheel_radius//2, wheel_y + wheel_radius//2],
        fill=wheel_inner_color
    )

    # Right wheel
    wheel2_x = bus_right - int(70 * scale)
    draw.ellipse(
        [wheel2_x - wheel_radius, wheel_y - wheel_radius,
         wheel2_x + wheel_radius, wheel_y + wheel_radius],
        fill=wheel_color
    )
    draw.ellipse(
        [wheel2_x - wheel_radius//2, wheel_y - wheel_radius//2,
         wheel2_x + wheel_radius//2, wheel_y + wheel_radius//2],
        fill=wheel_inner_color
    )

    # Safety light on top
    light_width = int(50 * scale)
    light_height = int(25 * scale)
    light_x = (size - light_width) // 2
    light_y = bus_top - int(35 * scale)
    draw.rounded_rectangle(
        [light_x, light_y, light_x + light_width, light_y + light_height],
        radius=int(8 * scale),
        fill=(244, 67, 54, 255)  # Red
    )

    # Light glow
    glow_radius = int(10 * scale)
    glow_x = size // 2
    glow_y = light_y + light_height // 2
    draw.ellipse(
        [glow_x - glow_radius, glow_y - glow_radius,
         glow_x + glow_radius, glow_y + glow_radius],
        fill=(255, 235, 59, 255)  # Yellow glow
    )

    # Add a subtle parent/family icon in the corner
    # Small heart or shield symbol in bottom right
    badge_size = int(120 * scale)
    badge_x = size - int(150 * scale)
    badge_y = size - int(150 * scale)

    # Heart shape (representing parent care)
    heart_color = (244, 67, 54, 255)  # Red
    heart_scale = badge_size / 100

    # Simple circle badge instead of complex heart for small sizes
    badge_radius = int(50 * scale)
    draw.ellipse(
        [badge_x - badge_radius, badge_y - badge_radius,
         badge_x + badge_radius, badge_y + badge_radius],
        fill=(255, 255, 255, 255),
        outline=(244, 67, 54, 255),
        width=int(4 * scale)
    )

    # Small person icon in the badge
    person_head_radius = int(12 * scale)
    person_x = badge_x
    person_y = badge_y - int(10 * scale)

    # Head
    draw.ellipse(
        [person_x - person_head_radius, person_y - person_head_radius,
         person_x + person_head_radius, person_y + person_head_radius],
        fill=heart_color
    )

    # Body (simple triangle/trapezoid)
    body_top = person_y + person_head_radius
    body_bottom = badge_y + int(20 * scale)
    body_width = int(25 * scale)
    draw.polygon([
        (person_x, body_top),
        (person_x - body_width, body_bottom),
        (person_x + body_width, body_bottom)
    ], fill=heart_color)

    return img

def main():
    """Generate all required icon sizes"""

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

    print("Generating app icons for Parents School Bus Tracking App...")
    print(f"Total icons to generate: {len(icon_configs)}")

    # Get the script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))

    for path, size in icon_configs.items():
        full_path = os.path.join(script_dir, path)

        # Create icon
        icon = create_icon(size)

        # Save with maximum quality
        icon.save(full_path, 'PNG', optimize=True)
        print(f"✓ Generated {path} ({size}x{size})")

    # Also generate a Windows .ico file
    print("\nGenerating Windows .ico file...")
    ico_sizes = [16, 32, 48, 64, 128, 256]
    ico_images = [create_icon(size) for size in ico_sizes]
    ico_path = os.path.join(script_dir, 'windows/runner/resources/app_icon.ico')
    ico_images[0].save(ico_path, format='ICO', sizes=[(s, s) for s in ico_sizes])
    print(f"✓ Generated windows/runner/resources/app_icon.ico")

    # Generate a preview image
    print("\nGenerating preview image...")
    preview = create_icon(512)
    preview_path = os.path.join(script_dir, 'app_icon_preview.png')
    preview.save(preview_path, 'PNG', optimize=True)
    print(f"✓ Generated app_icon_preview.png (512x512)")

    print("\n✅ All icons generated successfully!")
    print("\nPreview: app_icon_preview.png")
    print("The icons have been placed in their respective platform directories.")

if __name__ == '__main__':
    main()
