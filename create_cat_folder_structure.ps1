# 고양이 폴더 구조 생성
$gifs_path = "C:\Users\wntjd\Desktop\graduation\ChowChow-Sample\ChowChow-Front\flutter_app\assets\gifs"

$cat_groups = @(
    @{ name = "cat1_longhair"; label = "Longhair" },
    @{ name = "cat2_shorthair"; label = "Shorthair" },
    @{ name = "cat3_hairless"; label = "Hairless" }
)

$actions = @("idle", "eating", "petting", "exercise", "bath")

Write-Host "🐱 고양이 폴더 구조 생성 중...\n"

foreach ($cat in $cat_groups) {
    $cat_folder = Join-Path $gifs_path $cat.name

    if (-not (Test-Path $cat_folder)) {
        New-Item -ItemType Directory -Path $cat_folder -Force > $null
        Write-Host "✅ $($cat.name) 폴더 생성"
    }

    foreach ($action in $actions) {
        $action_folder = Join-Path $cat_folder "${$($cat.name)}_${action}"

        if (-not (Test-Path $action_folder)) {
            New-Item -ItemType Directory -Path $action_folder -Force > $null
            Write-Host "  └─ ${action}/ 생성"
        }
    }

    Write-Host ""
}

Write-Host "✨ 고양이 폴더 구조 완성!"
Write-Host "`n📁 생성된 구조:"
Get-ChildItem $gifs_path -Directory | Where-Object { $_.Name -like "cat*" } | ForEach-Object {
    Write-Host "  $($_.Name)/"
    Get-ChildItem $_.FullName -Directory | ForEach-Object {
        Write-Host "    └─ $($_.Name)/"
    }
}
