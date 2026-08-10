# ChowChow Backend 시작 스크립트
# 사용법: PowerShell에서 .\start-backend.ps1 실행

Write-Host "🚀 Backend 시작 중..." -ForegroundColor Green

ssh -i ~/.ssh/chowchow-key.pem ec2-user@35.78.87.150 `
  "cd /home/ec2-user && source .env && nohup java -jar app.jar > app.log 2>&1 &"

Start-Sleep -Seconds 5

Write-Host "✅ Backend 시작됨 (35.78.87.150:8080)" -ForegroundColor Green
Write-Host "📍 접속 테스트: http://35.78.87.150:8080/api/auth/login" -ForegroundColor Cyan
