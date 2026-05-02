#!/bin/bash

# Navigate to the app directory if not already there
cd "$(dirname "$0")/.."

# Ensure the data directory exists
mkdir -p .firebase_emulator_data

echo "🎮 Starting Firebase Emulators with Persistence..."
echo "📂 Data directory: app/.firebase_emulator_data"
echo "✨ Data will be saved automatically on exit (Ctrl+C)."

# Start emulators with import and export-on-exit flags
firebase emulators:start --import=.firebase_emulator_data --export-on-exit
