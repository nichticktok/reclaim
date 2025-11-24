#!/bin/bash
# Script to sync env/.env to assets/.env
# Run this whenever you update env/.env

if [ ! -f "env/.env" ]; then
    echo "❌ Error: env/.env file not found!"
    exit 1
fi

cp env/.env assets/.env
echo "✅ Synced env/.env to assets/.env"
echo "💡 Now you can run: flutter run"

