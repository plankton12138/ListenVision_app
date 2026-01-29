param(
    [int]$TimeoutSeconds = 300
)

$ErrorActionPreference = 'Stop'

Write-Host "Running Windows integration tests sequentially..." -ForegroundColor Cyan
Write-Host "Timeout per test: ${TimeoutSeconds}s" -ForegroundColor Cyan

$repoRoot = Split-Path -Parent $PSScriptRoot
$frontendPath = Join-Path $repoRoot 'frontend_flutter'

Push-Location $frontendPath
try {
    $timeoutArg = "--timeout ${TimeoutSeconds}s"

    Write-Host "[1/2] player_controls_icons_test.dart" -ForegroundColor Yellow
    flutter test integration_test/player_controls_icons_test.dart -d windows $timeoutArg

    Write-Host "[2/2] player_controls_launch_test.dart" -ForegroundColor Yellow
    flutter test integration_test/player_controls_launch_test.dart -d windows $timeoutArg
}
finally {
    Pop-Location
}

Write-Host "All integration tests completed." -ForegroundColor Green
