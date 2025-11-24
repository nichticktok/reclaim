# Background Color Customization Guide

## Quick Change

To change the background color theme, edit `lib/core/theme/app_design_system.dart` and modify the background color constants.

## Current Theme Options

### 1. Warm Brown/Amber Theme (Current - Default)
```dart
static const Color backgroundDeep = Color(0xFF1A1816);
static const Color backgroundMain = Color(0xFF242220);
static const Color surface = Color(0xFF2A2826);
```

### 2. Cool Blue/Purple Theme
```dart
static const Color backgroundDeep = Color(0xFF1A1B26);
static const Color backgroundMain = Color(0xFF242530);
static const Color surface = Color(0xFF2A2B36);
```

### 3. Warm Amber Theme
```dart
static const Color backgroundDeep = Color(0xFF1F1A14);
static const Color backgroundMain = Color(0xFF29241E);
static const Color surface = Color(0xFF332E28);
```

### 4. Neutral Gray Theme
```dart
static const Color backgroundDeep = Color(0xFF1E1E1E);
static const Color backgroundMain = Color(0xFF242424);
static const Color surface = Color(0xFF2A2A2A);
```

### 5. Deep Purple Theme
```dart
static const Color backgroundDeep = Color(0xFF1A1626);
static const Color backgroundMain = Color(0xFF242030);
static const Color surface = Color(0xFF2A2636);
```

## Custom Colors

To create your own color scheme:

1. Choose a base color (e.g., green, teal, indigo)
2. Create 3 shades from dark to light
3. Update the constants in `app_design_system.dart`

**Example - Green Theme:**
```dart
static const Color backgroundDeep = Color(0xFF1A1F1A);   // Dark green-gray
static const Color backgroundMain = Color(0xFF242924);     // Medium green-gray
static const Color surface = Color(0xFF2A332A);           // Light green-gray
```

**Example - Teal Theme:**
```dart
static const Color backgroundDeep = Color(0xFF1A1F20);   // Dark teal-gray
static const Color backgroundMain = Color(0xFF24292A);   // Medium teal-gray
static const Color surface = Color(0xFF2A3335);          // Light teal-gray
```

## Color Picker Tool

Use online tools like:
- https://coolors.co/ - Generate color palettes
- https://material.io/design/color/the-color-system.html - Material Design colors
- https://www.color-hex.com/ - Color code converter

## Tips

- Keep the contrast between colors subtle (difference of ~10-15 in hex values)
- Test readability with white text
- Darker colors at the top, lighter at the bottom for depth
- Match the color tone with your primary accent color (orange in this app)

