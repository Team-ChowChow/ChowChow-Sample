# ChowChow Backend 중단 스크립트
# 사용법: PowerShell에서 .\stop-backend.ps1 실행

Write-Host "⏹️  Backend 중단 중..." -ForegroundColor Yellow

ssh -i ~/.ssh/chowchow-key.pem ec2-user@35.78.87.150 "pkill -9 java"

Write-Host "✅ Backend 중단됨" -ForegroundColor Green
