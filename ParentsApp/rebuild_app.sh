#!/bin/bash

echo "🧹 Cleaning Flutter build..."
flutter clean

echo ""
echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "🚀 Building and running app..."
echo "   Watch for changes:"
echo "   ✅ Background dot pattern"
echo "   ✅ School bus logo in header"
echo "   ✅ No Uganda flag/code (just phone icon)"
echo ""

flutter run
