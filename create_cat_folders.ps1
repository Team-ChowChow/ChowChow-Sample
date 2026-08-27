$gifs_path = "C:\Users\wntjd\Desktop\graduation\ChowChow-Sample\ChowChow-Front\flutter_app\assets\gifs"

$cat_groups = @(
    @{ name = "cat1_longhair"; label = "Longhair" },
    @{ name = "cat2_shorthair"; label = "Shorthair" },
    @{ name = "cat3_hairless"; label = "Hairless" }
)

$actions = @("idle", "eating", "petting", "exercise", "bath")

Write-Host "Creating cat folder structure..."

foreach ($cat in $cat_groups) {
    $cat_folder = Join-Path $gifs_path $cat.name

    if (-not (Test-Path $cat_folder)) {
        New-Item -ItemType Directory -Path $cat_folder -Force > $null
        Write-Host "Created: $($cat.name)/"
    }

    foreach ($action in $actions) {
        $action_folder = Join-Path $cat_folder "$($cat.name)_$action"

        if (-not (Test-Path $action_folder)) {
            New-Item -ItemType Directory -Path $action_folder -Force > $null
            Write-Host "  - $action/"
        }
    }
}

Write-Host "`nFolder structure complete!"
