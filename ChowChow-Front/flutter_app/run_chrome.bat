@echo off
cd /d "%~dp0"
echo [ChowChow] Chrome에서 390x844 미리보기로 실행합니다...
echo Windows 네이티브 실행은 개발자 모드가 필요합니다. run_windows.bat 참고.
flutter run -d chrome --web-browser-flag="--window-size=420,900" --web-browser-flag="--window-position=100,50"
pause
