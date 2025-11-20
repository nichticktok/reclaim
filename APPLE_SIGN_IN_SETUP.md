# Apple Sign In Setup Guide

## Issue: Sign in with Apple not working in debug mode

This guide will help you fix Apple Sign In for your iOS app.

## Step 1: Enable Sign in with Apple Capability in Xcode

1. Open your project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select the **Runner** target in the project navigator

3. Go to the **Signing & Capabilities** tab

4. Click the **+ Capability** button

5. Search for and add **"Sign in with Apple"**

6. Make sure your **Team** is selected in the Signing section

## Step 2: Verify Entitlements File

The entitlements file has been created at:
- `ios/Runner/Runner.entitlements`

It should contain:
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

## Step 3: Link Entitlements in Xcode Project

1. In Xcode, select the **Runner** target
2. Go to **Build Settings** tab
3. Search for "Code Signing Entitlements"
4. Set the value to: `Runner/Runner.entitlements`

## Step 4: Configure Bundle ID in Apple Developer Console

1. Go to [Apple Developer Console](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** → Your App ID (com.example.recalim)
4. Enable **Sign in with Apple** capability
5. Save the changes

## Step 5: Configure Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Authentication** → **Sign-in method**
4. Enable **Apple** provider
5. Configure the OAuth redirect URL if needed

## Step 6: Clean and Rebuild

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

## Common Issues

### Issue: "Sign in with Apple not available on this platform"
- **Solution**: Make sure you're running on a physical iOS device or iOS 13+ simulator
- Apple Sign In requires iOS 13+ and doesn't work on older simulators

### Issue: "Invalid client" or "Invalid configuration"
- **Solution**: 
  1. Verify Bundle ID matches in Xcode and Apple Developer Console
  2. Make sure Sign in with Apple is enabled in Apple Developer Console
  3. Wait a few minutes after enabling in Apple Developer Console (propagation delay)

### Issue: Works in Release but not Debug
- **Solution**: 
  1. Make sure your debug provisioning profile includes Sign in with Apple
  2. Regenerate provisioning profiles in Xcode
  3. Check that your Apple Developer account has Sign in with Apple enabled

### Issue: "The operation couldn't be completed"
- **Solution**:
  1. Make sure you're signed in with an Apple ID on your device
  2. Check Settings → [Your Name] → Sign-In & Security → Apple ID
  3. Try signing out and back in to your Apple ID on the device

## Testing

1. Run on a **physical iOS device** (recommended) or iOS 13+ simulator
2. Make sure you're signed in with an Apple ID on the device
3. Tap "Continue with Apple" button
4. You should see the Apple Sign In sheet

## Debug Mode Notes

- Sign in with Apple works in both debug and release modes
- However, you must have:
  - Valid provisioning profile with Sign in with Apple capability
  - Bundle ID configured in Apple Developer Console
  - Sign in with Apple enabled in Firebase Console

## Additional Resources

- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Firebase Apple Auth Setup](https://firebase.google.com/docs/auth/ios/apple)

