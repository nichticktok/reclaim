# iPad Debug Connection Fix

## Issue
"Connection reset by peer" error when running Flutter app on iPad (works fine on iPhone).

## Solutions Applied

### 1. Network Permissions Added to Info.plist
Added network permissions to allow Flutter debug service to connect:
- `NSAppTransportSecurity` with local networking enabled
- `NSLocalNetworkUsageDescription` for network access
- `NSBonjourServices` for Flutter Observatory service

### 2. Troubleshooting Steps

#### Step 1: Ensure Same Network
- Make sure both your Mac and iPad are on the **same Wi-Fi network**
- Disable VPN if active on either device
- Check that both devices can ping each other

#### Step 2: Check Firewall Settings (Mac)
1. Go to **System Settings > Network > Firewall**
2. Temporarily disable firewall to test
3. If it works, add Flutter/Xcode to allowed apps:
   - Click "Options" in Firewall settings
   - Add `/Applications/Xcode.app` and `/usr/local/bin/flutter` to allowed apps

#### Step 3: Use USB Connection (Recommended)
Instead of Wi-Fi, connect iPad via USB:
```bash
# Connect iPad via USB cable
# Then run:
flutter devices
# You should see your iPad listed
flutter run -d <ipad-device-id>
```

#### Step 4: Check iPad Network Settings
1. On iPad: **Settings > Privacy & Security > Local Network**
2. Make sure your app has permission to access local network
3. If your app isn't listed, run it once and check again

#### Step 5: Clean and Rebuild
```bash
# Clean Flutter build
flutter clean

# Clean iOS build
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

# Rebuild
flutter pub get
flutter run
```

#### Step 6: Check Xcode Settings
1. Open project in Xcode: `open ios/Runner.xcworkspace`
2. Go to **Product > Scheme > Edit Scheme**
3. Under **Run > Options**, check:
   - "Allow Location Simulation" is enabled
   - "Debug executable" is checked

#### Step 7: Restart Services
```bash
# Kill any existing Flutter processes
killall -9 dart
killall -9 flutter

# Restart Flutter daemon
flutter doctor -v
```

#### Step 8: Check iPad iOS Version
- Ensure iPad is running iOS 13.0 or later (as per Podfile requirement)
- Update iPad to latest iOS version if possible

#### Step 9: Alternative: Use Release Mode
If debug mode continues to fail, try release mode:
```bash
flutter run --release -d <ipad-device-id>
```

## Common Causes

1. **Network Isolation**: iPad and Mac on different networks
2. **Firewall Blocking**: Mac firewall blocking Flutter debug port
3. **VPN Interference**: VPN routing traffic differently
4. **Bonjour Issues**: mDNS/Bonjour not working properly
5. **iPad Network Restrictions**: iPad has stricter network permissions

## Verification

After applying fixes, verify connection:
```bash
# List devices
flutter devices

# Try running with verbose output
flutter run -d <ipad-device-id> -v
```

## If Still Not Working

1. Try running on a different iPad (if available)
2. Check Flutter logs: `flutter logs`
3. Check Xcode console for additional errors
4. Try creating a new Flutter project and see if it works
5. Check if other Flutter apps work on the same iPad

## Additional Notes

- The network permissions added to Info.plist should help with local network access
- USB connection is more reliable than Wi-Fi for debugging
- Some corporate networks block mDNS/Bonjour, which Flutter uses for device discovery

