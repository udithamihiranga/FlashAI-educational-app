@echo off
REM Launcher Icon Generation Script
REM Run from project root: assets\icons\generate_icons.bat

echo ========================================
echo FlashAI Launcher Icon Generator
echo ========================================
echo.

echo Step 1: Installing dependencies...
flutter pub get

echo.
echo Step 2: Generating launcher icons...
flutter pub run flutter_launcher_icons

echo.
echo Step 3: Icons generated! Check the generated files:
echo   - Android: android/app/src/main/res/mipmap-*/
echo   - iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/
echo   - Windows: windows/runner/resources/app_icon.ico
echo   - macOS: macos/Runner/Assets.xcassets/AppIcon.appiconset/
echo   - Web: web/icons/

echo.
echo Done!