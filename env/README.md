# Environment Configuration

This folder contains environment variables for local development.

## Setup

The `.env` file in this folder contains sensitive API keys and configuration.

**⚠️ IMPORTANT: This file is NOT committed to version control (see .gitignore)**

## File Structure

```
env/
  ├── .env          # Environment variables (gitignored)
  └── README.md     # This file
```

## Usage

The app automatically loads environment variables from `env/.env` at runtime.

### For Local Development

1. Create `env/.env` file (if it doesn't exist)
2. Add your API keys:
   ```
   GEMINI_API_KEY=your_api_key_here
   ```
3. Run the app normally - it will automatically load from the file

### For Production/Mobile Builds

For production builds or when running on mobile devices, use `--dart-define`:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
```

Or for builds:

```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_api_key_here
```

## Priority

The app checks for API keys in this order:
1. `--dart-define=GEMINI_API_KEY=...` (highest priority - used in production)
2. `env/.env` file (for local development)
3. Empty string (if neither is found)

## Security Notes

- Never commit `.env` files to version control
- The `.env` file is already in `.gitignore`
- For production, always use `--dart-define` or secure environment variable management
- Rotate API keys if they are ever exposed

