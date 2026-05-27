@echo off
cd /d "%~dp0"

echo [ChowChow] Windows 390x844 창으로 실행합니다...
echo.

REM 개발자 모드(심볼릭 링크) 확인
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense 2^>nul ^| findstr 0x1') do set DEVMODE=%%a

if "%DEVMODE%"=="0x1" (
  echo 개발자 모드: 켜짐
) else (
  echo.
  echo [경고] Windows 개발자 모드가 꺼져 있으면 빌드가 실패합니다.
  echo   설정 - 개인 정보 보호 및 보안 - 개발자용 - 개발자 모드 ON
  echo   또는 관리자 PowerShell: start ms-settings:developers
  echo.
  echo Chrome으로 실행하려면 run_chrome.bat 을 사용하세요.
  echo.
  pause
)

flutter run -d windows
pause
