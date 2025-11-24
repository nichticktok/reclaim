#!/bin/bash
# Script to run Flutter app with API key from env/.env file

# Check if .env file exists
if [ ! -f "env/.env" ]; then
    echo "❌ Error: env/.env file not found!"
    echo "Please create env/.env with your GEMINI_API_KEY"
    exit 1
fi

# Extract API key from .env file
API_KEY=$(grep "^GEMINI_API_KEY=" env/.env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | tr -d ' ')

if [ -z "$API_KEY" ]; then
    echo "❌ Error: GEMINI_API_KEY not found in env/.env"
    exit 1
fi

echo "✅ Found GEMINI_API_KEY in env/.env"
echo "🚀 Running Flutter app with API key..."

# Run Flutter with the API key
flutter run --dart-define=GEMINI_API_KEY="$API_KEY" "$@"

