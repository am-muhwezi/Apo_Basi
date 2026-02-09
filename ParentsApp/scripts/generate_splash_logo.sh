#!/bin/bash
# Script to generate Android splash logo mipmap assets from reallogo.png
# Requires: ImageMagick (convert)

SRC="assets/images/reallogo.png"
RES_DIR="android/app/src/main/res"

sizes=(
  "mipmap-mdpi:48"
  "mipmap-hdpi:72"
  "mipmap-xhdpi:96"
  "mipmap-xxhdpi:144"
  "mipmap-xxxhdpi:192"
)

for entry in "${sizes[@]}"; do
  folder="${entry%%:*}"
  size="${entry##*:}"
  mkdir -p "$RES_DIR/$folder"
  convert "$SRC" -resize ${size}x${size} "$RES_DIR/$folder/splash_logo.png"
done

echo "Splash logo assets generated."
