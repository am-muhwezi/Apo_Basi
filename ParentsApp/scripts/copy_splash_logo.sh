#!/bin/bash
# Script to verify/copy splash_logo.png to all required mipmap folders for Android splash screen
# Place this script in the ParentsApp directory and run: bash scripts/copy_splash_logo.sh

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
  if [ ! -f "$RES_DIR/$folder/splash_logo.png" ]; then
    echo "Copying and resizing $SRC to $RES_DIR/$folder/splash_logo.png ($size x $size)"
    magick "$SRC" -resize ${size}x${size} "$RES_DIR/$folder/splash_logo.png"
  else
    echo "$RES_DIR/$folder/splash_logo.png already exists."
  fi
done

echo "Splash logo verification/copy complete."
