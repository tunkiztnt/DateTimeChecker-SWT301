param(
    [switch]$CiMode,
    [switch]$OpenReport
)

. "$PSScriptRoot\..\..\scripts\common.ps1"

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding
$ErrorActionPreference = 'Stop'
$env:ALLURE_NO_ANALYTICS = '1'

$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$reportRoot = Join-Path $repoRoot 'topics\reports\topic07-cicd'
$releaseRoot = Join-Path $reportRoot 'release-bundle'
$summaryPath = Join-Path $reportRoot 'ci-summary.md'
$deploymentZipPath = Join-Path $reportRoot 'DateTimeChecker-release.zip'
$playwrightReportPath = Join-Path $repoRoot 'playwright-report'
$allureResultsPath = Join-Path $repoRoot 'allure-results'
$allureReportPath = Join-Path $repoRoot 'allure-report'
$currentRunImagesPath = Join-Path $repoRoot 'topics\05-visual-regression\current-run-images'
$diffImagesPath = Join-Path $repoRoot 'topics\05-visual-regression\diff-images'
$serverStarted = $false
$pipelinePassed = $false
$stageResults = New-Object System.Collections.Generic.List[object]
$startedAt = Get-Date

function Add-StageResult {
    param(
        [string]$Stage,
        [string]$Status,
        [string]$Details
    )

    $stageResults.Add([PSCustomObject]@{
        Stage = $Stage
        Status = $Status
        Details = $Details
    }) | Out-Null
}

function Invoke-Stage {
    param(
        [string]$Title,
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkCyan

    try {
        & $Action
        Add-StageResult -Stage $Title -Status 'PASS' -Details 'Completed successfully'
        Write-Host "[PASS] $Title" -ForegroundColor Green
    } catch {
        Add-StageResult -Stage $Title -Status 'FAIL' -Details $_.Exception.Message
        Write-Host "[FAIL] $Title" -ForegroundColor Red
        throw
    }
}

function Reset-Topic7Artifacts {
    $pathsToClean = @(
        $reportRoot,
        $playwrightReportPath,
        $allureResultsPath,
        $allureReportPath,
        $currentRunImagesPath,
        $diffImagesPath
    )

    foreach ($path in $pathsToClean) {
        if (Test-Path $path) {
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }

    New-Item -ItemType Directory -Path $reportRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $currentRunImagesPath -Force | Out-Null
    New-Item -ItemType Directory -Path $diffImagesPath -Force | Out-Null
}

function Invoke-ApiSmokeTests {
    $validPayload = @{ day = '15'; month = '6'; year = '2026' } | ConvertTo-Json -Compress
    $invalidPayload = @{ day = '31'; month = '4'; year = '2026' } | ConvertTo-Json -Compress

    $validResponse = Invoke-RestMethod -Uri 'http://localhost:4173/api/datetime/check' -Method Post -ContentType 'application/json' -Body $validPayload
    if (-not $validResponse.valid) {
        throw "Expected valid API response but received invalid result."
    }

    if ($validResponse.details.display -ne '15/06/2026') {
        throw "Expected display value 15/06/2026 but got $($validResponse.details.display)."
    }

    $invalidResponse = Invoke-RestMethod -Uri 'http://localhost:4173/api/datetime/check' -Method Post -ContentType 'application/json' -Body $invalidPayload
    if ($invalidResponse.valid) {
        throw "Expected invalid API response but received valid result."
    }

    $errorText = ($invalidResponse.errors -join ' | ')
    if ($errorText -notmatch 'has only 30 days') {
        throw "Expected invalid-date message about 30 days but got: $errorText"
    }
}

function Invoke-PlaywrightSuite {
    param(
        [string]$Title,
        [string[]]$Targets
    )

    Write-Host "[RUN] npx playwright test $($Targets -join ' ')" -ForegroundColor Yellow
    & npx playwright test @Targets
    if ($LASTEXITCODE -ne 0) {
        throw "Playwright suite failed: $Title"
    }
}

function New-DeploymentBundle {
    if (Test-Path $releaseRoot) {
        Remove-Item -LiteralPath $releaseRoot -Recurse -Force
    }

    New-Item -ItemType Directory -Path $releaseRoot -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $releaseRoot 'app\classes') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $releaseRoot 'app\static') -Force | Out-Null

    Copy-Item -Path (Join-Path $repoRoot 'out\classes\*') -Destination (Join-Path $releaseRoot 'app\classes') -Recurse -Force
    Copy-Item -Path (Join-Path $repoRoot 'src\main\resources\static\*') -Destination (Join-Path $releaseRoot 'app\static') -Recurse -Force
    Copy-Item -Path (Join-Path $repoRoot 'scripts\run.ps1') -Destination $releaseRoot -Force
    Copy-Item -Path (Join-Path $repoRoot 'run.bat') -Destination $releaseRoot -Force

    $deploymentReadme = @'
DateTimeChecker Release Bundle
==============================

This package is generated by Topic 7 CI/CD demo.

Contents:
- app\classes : compiled Java classes
- app\static  : web UI assets
- run.ps1 / run.bat : local startup helpers

Deploy note:
- copy this bundle to a Windows machine with JDK 17+
- run run.bat or powershell -File run.ps1
'@
    Set-Content -Path (Join-Path $releaseRoot 'DEPLOY-README.txt') -Value $deploymentReadme -Encoding UTF8

    if (Test-Path $deploymentZipPath) {
        Remove-Item -LiteralPath $deploymentZipPath -Force
    }

    Compress-Archive -Path (Join-Path $releaseRoot '*') -DestinationPath $deploymentZipPath -Force
}

function Write-PipelineSummary {
    $finishedAt = Get-Date
    $duration = [math]::Round(($finishedAt - $startedAt).TotalSeconds, 1)
    $pipelineStatus = if ($pipelinePassed) { 'PASS' } else { 'FAIL' }

    $lines = @(
        '# Topic 7 CI/CD Summary',
        '',
        "- Started: $($startedAt.ToString('yyyy-MM-dd HH:mm:ss'))",
        "- Finished: $($finishedAt.ToString('yyyy-MM-dd HH:mm:ss'))",
        "- Duration: ${duration}s",
        "- Final status: $pipelineStatus",
        '',
        '## Stage Results',
        ''
    )

    foreach ($stageResult in $stageResults) {
        $lines += "- $($stageResult.Stage): $($stageResult.Status) - $($stageResult.Details)"
    }

    $lines += @(
        '',
        '## Artifacts',
        '',
        '- Playwright report: playwright-report',
        '- Allure report: allure-report',
        '- Visual current images: topics/05-visual-regression/current-run-images',
        '- Visual diff images: topics/05-visual-regression/diff-images',
        '- Release package: topics/reports/topic07-cicd/DateTimeChecker-release.zip'
    )

    Set-Content -Path $summaryPath -Value $lines -Encoding UTF8
}

Push-Location $repoRoot
try {
    try {
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host " TOPIC 7 - CI/CD REPORTING PIPELINE" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "Mode: $([string]::Join(', ', @($(if ($CiMode) { 'CI' } else { 'Local' }), 'Build + API + E2E + Visual + Report + Package')))" -ForegroundColor Yellow

        Reset-Topic7Artifacts

        Invoke-Stage -Title 'Build Application' -Action {
            & "$repoRoot\scripts\build.ps1"
            if ($LASTEXITCODE -ne 0) {
                throw "Build step returned exit code $LASTEXITCODE."
            }
        }

        Invoke-Stage -Title 'Start Backend Server' -Action {
            & "$repoRoot\scripts\start-server.ps1" | Out-Host
            $serverStarted = $true
        }

        Invoke-Stage -Title 'API Smoke Tests' -Action {
            Invoke-ApiSmokeTests
        }

        Invoke-Stage -Title 'Web E2E Tests' -Action {
            $env:HEADLESS = 'true'
            Invoke-PlaywrightSuite -Title 'Web E2E Tests' -Targets @('topics/02-web-e2e-testing/')
        }

        Invoke-Stage -Title 'Visual Regression Tests' -Action {
            $env:HEADLESS = 'true'
            Invoke-PlaywrightSuite -Title 'Visual Regression Tests' -Targets @('topics/05-visual-regression/')
        }

        Invoke-Stage -Title 'Generate Allure Report' -Action {
            & npx allure generate allure-results --clean -o allure-report
            if ($LASTEXITCODE -ne 0) {
                throw "Allure report generation failed."
            }
        }

        Invoke-Stage -Title 'Package Release Artifact' -Action {
            New-DeploymentBundle
        }

        $pipelinePassed = $true
    } catch {
        Write-Host ""
        Write-Host "[PIPELINE ERROR] $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        $env:HEADLESS = $null

        if ($serverStarted) {
            try {
                & "$repoRoot\scripts\stop-server.ps1" | Out-Host
            } catch {
                Write-Host "[WARNING] Failed to stop backend cleanly: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        Write-PipelineSummary

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host " TOPIC 7 ARTIFACTS" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "Summary         : $summaryPath" -ForegroundColor Green
        Write-Host "Playwright      : $playwrightReportPath" -ForegroundColor Green
        Write-Host "Allure          : $allureReportPath" -ForegroundColor Green
        Write-Host "Visual Current  : $currentRunImagesPath" -ForegroundColor Green
        Write-Host "Visual Diff     : $diffImagesPath" -ForegroundColor Green
        if (Test-Path $deploymentZipPath) {
            Write-Host "Release ZIP     : $deploymentZipPath" -ForegroundColor Green
        }

        if (-not $CiMode -and $OpenReport -and (Test-Path $allureReportPath)) {
            Write-Host ""
            Write-Host "[INFO] Opening Allure report..." -ForegroundColor Yellow
            & npx allure open allure-report
        }
    }

    if ($pipelinePassed) {
        exit 0
    }

    exit 1
} finally {
    Pop-Location
}
