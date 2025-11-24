# Environment Setup Guide

## ⚠️ Security Warning

**NEVER commit API keys to version control!** All `.env` files containing real API keys are gitignored.

## Quick Setup

1. **Copy the template file:**
   ```bash
   cp assets/.env.example assets/.env
   ```

2. **Edit `assets/.env` and add your actual API key:**
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

That's it! The app will automatically load the API key from `assets/.env`.

## File Structure

```
assets/
  ├── .env.example    # Template file (safe to commit)
  └── .env            # Your actual keys (gitignored, NEVER commit!)

env/
  ├── .env            # Alternative location (gitignored)
  └── README.md       # Documentation
```

## How It Works

The app loads the API key in this priority order:

1. **`--dart-define=GEMINI_API_KEY=...`** (if provided via command line)
2. **`assets/.env`** (loaded from app assets - works on all platforms)
3. **File system paths** (fallback for local development)

## Security Best Practices

✅ **DO:**
- Keep `assets/.env` in `.gitignore`
- Use `assets/.env.example` as a template
- Use `--dart-define` for CI/CD pipelines
- Rotate keys if they're ever exposed

❌ **DON'T:**
- Commit `assets/.env` to git
- Share API keys in chat/email
- Hardcode keys in source code
- Commit `env/.env` to git

## For Team Members

When cloning the repository:

1. Copy the example file:
   ```bash
   cp assets/.env.example assets/.env
   ```

2. Get the API key from your team's secure password manager

3. Add it to `assets/.env`

4. Run the app - it will work automatically!

## For Production/CI/CD

Use environment variables or `--dart-define`:

```bash
flutter build apk --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
```

Or set it in your CI/CD platform's environment variables.

