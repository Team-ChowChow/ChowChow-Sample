# Flutter 버전 실행 방법

## 1) Flutter 설치 확인

```bash
flutter --version
flutter doctor
```

## 2) 의존성 설치

```bash
cd flutter_app
flutter pub get
```

## 3) Windows 창으로 실행 (Android Studio 불필요, 추천)

```bash
cd flutter_app
flutter run -d windows
```

또는 `run_windows.bat` 더블클릭.

첫 빌드는 2~5분 걸릴 수 있습니다. 완료되면 **별도 데스크톱 창**에 앱이 뜹니다.

## 4) 안드로이드 / 기타

```bash
flutter run
```

안드로이드 기기 지정 실행:

```bash
flutter devices
flutter run -d <device_id>
```
