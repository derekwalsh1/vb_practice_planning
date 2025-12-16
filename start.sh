#!/bin/bash

echo "🏐 VB Practice Plan - Quick Start"
echo "================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter from https://flutter.dev"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Check Flutter doctor
echo "📋 Running Flutter doctor..."
flutter doctor

echo ""
echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "📱 Available devices:"
flutter devices

echo ""
echo "🚀 To run the app:"
echo "   flutter run"
echo ""
echo "   Or specify a device:"
echo "   flutter run -d <device-id>"
echo ""
echo "✨ Ready to coach! 🏐"
