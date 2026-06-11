param(
    [string]$ApiKey,
    [switch]$OfflineSample,
    [switch]$AutoApprove
)

. "$PSScriptRoot\common.ps1"
if (-not $OfflineSample) {
    . "$PSScriptRoot\gemini-common.ps1"
}

$reportsDir = "$PSScriptRoot\..\reports"
if (!(Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

$testcasesFile = "$reportsDir\ai-generated-testcases.json"
$failuresBeforeFile = "$reportsDir\ai-selenium-failures-before-fix.tsv"
$fixAnalysisFile = "$reportsDir\ai-fix-analysis.json"
$failuresAfterFile = "$reportsDir\ai-selenium-failures-after-fix.tsv"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " STARTING AI SELF-HEALING & REGRESSION DEMO" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

# Define 3 backticks dynamically using character code 96 to avoid script escaping bugs
$bts = [string]([char]96) + [string]([char]96) + [string]([char]96)

# ---------------------------------------------------------------------
# STEP 1: Generate dynamic test cases using Gemini (or Offline Mock)
# ---------------------------------------------------------------------
Write-Host "[STEP 1] Dang sinh kich ban kiem thu bang tri tue nhan tao..." -ForegroundColor Yellow
if ($OfflineSample) {
    $testcasesJson = Get-Content "$PSScriptRoot\mock-testcases.json" -Raw
    [System.IO.File]::WriteAllText($testcasesFile, $testcasesJson)
    Start-Sleep -Seconds 1
    Write-Host "[INFO] Da sinh 4 testcase mau va luu tai reports/ai-generated-testcases.json" -ForegroundColor Gray
} else {
    $prompt = "Generate exactly 4 diverse test cases for the DateTimeChecker application. The fields must check range validations: Day (1-31), Month (1-12), Year (1000-3000). Include one normal valid date, one day-in-month boundary violation (like April 31), one leap year valid date (Feb 29 2024), and one non-leap year invalid date (Feb 29 2025). Output must be a raw JSON array of objects with keys: id, name, day, month, year, expectedValid."
    
    $aiResponse = Invoke-GeminiPrompt -apiKey $ApiKey -systemInstruction "You are an SQA expert. Return only raw JSON array." -userPrompt $prompt
    if ($null -eq $aiResponse) {
        Write-Host "[ERROR] Khong the ket noi Gemini API de sinh testcase. Chuyen sang offline mode..." -ForegroundColor Red
        $OfflineSample = $true
        $testcasesJson = Get-Content "$PSScriptRoot\mock-testcases.json" -Raw
        [System.IO.File]::WriteAllText($testcasesFile, $testcasesJson)
    } else {
        $cleanedJson = $aiResponse.Trim()
        
        # Clean markdown wrappers if returned
        $jsonWrapper = $bts + "json"
        if ($cleanedJson.StartsWith($jsonWrapper)) {
            $cleanedJson = $cleanedJson.Substring($jsonWrapper.Length).Trim()
        }
        if ($cleanedJson.StartsWith($bts)) {
            $cleanedJson = $cleanedJson.Substring($bts.Length).Trim()
        }
        if ($cleanedJson.EndsWith($bts)) {
            $cleanedJson = $cleanedJson.Substring(0, $cleanedJson.Length - $bts.Length).Trim()
        }
        
        [System.IO.File]::WriteAllText($testcasesFile, $cleanedJson)
        Write-Host "[INFO] Da sinh 4 testcase tu Gemini API va luu tai reports/ai-generated-testcases.json" -ForegroundColor Gray
    }
}

# Load test cases
$testCases = Get-Content $testcasesFile -Raw | ConvertFrom-Json

# ---------------------------------------------------------------------
# STEP 2: Create temporary source directory & inject controlled defect
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "[STEP 2] Dang thiet lap moi truong kiem thu tam thoi va dua loi thu nghiem (controlled defect)..." -ForegroundColor Yellow
$tempSrcDir = "$PSScriptRoot\..\out\temp_src"
$tempClassesDir = "$PSScriptRoot\..\out\temp_classes"

if (Test-Path $tempSrcDir) { Remove-Item $tempSrcDir -Recurse -Force | Out-Null }
if (Test-Path $tempClassesDir) { Remove-Item $tempClassesDir -Recurse -Force | Out-Null }

New-Item -ItemType Directory -Path $tempSrcDir -Force | Out-Null
New-Item -ItemType Directory -Path $tempClassesDir -Force | Out-Null

# Copy source code files
Copy-Item "$PSScriptRoot\..\src\main\java\com\datetimechecker\App.java" -Destination "$tempSrcDir\App.java"
$valServicePath = "$PSScriptRoot\..\src\main\java\com\datetimechecker\DateTimeValidationService.java"
$tempValServicePath = "$tempSrcDir\DateTimeValidationService.java"
Copy-Item $valServicePath -Destination $tempValServicePath

# Inject controlled defect: Make April (Month 4) return 31 days instead of 30!
$serviceCode = Get-Content $tempValServicePath -Raw
$defectiveCode = $serviceCode -replace 'case 11:\s*return 30;', 'case 11: return 31; // CONTROLLED DEFECT INJECTED BY AI DEMO'

# Use .NET WriteAllText to write UTF-8 without BOM so javac doesn't crash on \ufeff
[System.IO.File]::WriteAllText($tempValServicePath, $defectiveCode)

# Compile defective code
$tools = Get-JavaTools
& $tools.Javac -encoding UTF-8 -d $tempClassesDir "$tempSrcDir\*.java"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Khong the bien dich source code bi loi." -ForegroundColor Red
    exit 1
}
Write-Host "[INFO] Da dua loi 'Thang 4 co 31 ngay' vao file tam va bien dich thanh cong." -ForegroundColor Gray

# ---------------------------------------------------------------------
# STEP 3: Start defective server and run Selenium simulation
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "[STEP 3] Dang chay ung dung loi va gia lap Selenium kiem thu..." -ForegroundColor Yellow

$serverProcess = Start-Process -FilePath $tools.Java -ArgumentList "-cp", "$tempClassesDir", "com.datetimechecker.App" -PassThru -NoNewWindow
Start-Sleep -Seconds 2 # Wait for boot

# Run testcases against defective app
$failures = @()
$tsvHeader = "TestID`tName`tInput`tExpected`tActual`tResult"
$tsvLines = @($tsvHeader)

foreach ($tc in $testCases) {
    $dateStr = "$($tc.day)/$($tc.month)/$($tc.year)"
    Write-Host "[INFO] Dang kiem thu: $($tc.id) - $($tc.name) ($dateStr)... " -NoNewline
    
    # Send HTTP request to check endpoint
    $body = @{ day = $tc.day; month = $tc.month; year = $tc.year } | ConvertTo-Json
    try {
        $res = Invoke-RestMethod -Uri "http://localhost:4173/api/datetime/check" -Method Post -ContentType "application/json" -Body $body
        $actualValid = $res.valid
        
        if ($actualValid -eq $tc.expectedValid) {
            Write-Host "PASS" -ForegroundColor Green
            $tsvLines += "$($tc.id)`t$($tc.name)`t$dateStr`t$($tc.expectedValid)`t$actualValid`tPASS"
        } else {
            Write-Host "FAIL" -ForegroundColor Red
            Write-Host "   (Ly do: Mong doi valid=$($tc.expectedValid), Thuc te valid=$actualValid)" -ForegroundColor DarkRed
            $tsvLines += "$($tc.id)`t$($tc.name)`t$dateStr`t$($tc.expectedValid)`t$actualValid`tFAIL"
            $failures += $tc
        }
    } catch {
        Write-Host "ERROR (Khong ket noi duoc)" -ForegroundColor Red
        $tsvLines += "$($tc.id)`t$($tc.name)`t$dateStr`t$($tc.expectedValid)`tERROR`tFAIL"
        $failures += $tc
    }
}

$tsvLines | Out-File $failuresBeforeFile -Encoding utf8 -Force
Write-Host "[INFO] Da ghi bao cao loi truoc khi sua vao: reports/ai-selenium-failures-before-fix.tsv" -ForegroundColor Gray

# Stop server
Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------
# STEP 4: AI Analysis & Fix Generation (Self-Healing)
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "[STEP 4] Dang gui ma nguon loi va bao cao test that bai cho AI Assistant phan tich..." -ForegroundColor Yellow

$fixAnalysisJson = ""
if ($OfflineSample -or $null -eq $ApiKey) {
    $fixAnalysisJson = Get-Content "$PSScriptRoot\mock-fix-analysis.json" -Raw
    Start-Sleep -Seconds 2
} else {
    # Call Gemini API
    $failuresTsv = Get-Content $failuresBeforeFile -Raw
    $sourceContent = Get-Content $tempValServicePath -Raw
    
    $prompt = "We ran the generated SQA testcases on a temporary build of the DateTimeChecker app and encountered failures. Here is the failure report:`n$failuresTsv`n`nAnd here is the source code of the validation class:`n$sourceContent`n`nPlease diagnose the issue, locate the bug, and provide a JSON response explaining the defect and how to patch it. The response must be a valid JSON object with the following keys: defect_detected, file_to_patch, bug_description, suggested_fix, original_code_snippet, replacement_code_snippet. Do not return any markdown wrapper."

    $aiDiagnosis = Invoke-GeminiPrompt -apiKey $ApiKey -systemInstruction "You are an SQA expert diagnosing defect, return only raw JSON." -userPrompt $prompt
    if ($null -eq $aiDiagnosis) {
        $fixAnalysisJson = Get-Content "$PSScriptRoot\mock-fix-analysis.json" -Raw
    } else {
        $cleanedJson = $aiDiagnosis.Trim()
        $jsonWrapper = $bts + "json"
        if ($cleanedJson.StartsWith($jsonWrapper)) {
            $cleanedJson = $cleanedJson.Substring($jsonWrapper.Length).Trim()
        }
        if ($cleanedJson.StartsWith($bts)) {
            $cleanedJson = $cleanedJson.Substring($bts.Length).Trim()
        }
        if ($cleanedJson.EndsWith($bts)) {
            $cleanedJson = $cleanedJson.Substring(0, $cleanedJson.Length - $bts.Length).Trim()
        }
        $fixAnalysisJson = $cleanedJson
    }
}

[System.IO.File]::WriteAllText($fixAnalysisFile, $fixAnalysisJson)
$analysis = $fixAnalysisJson | ConvertFrom-Json

Write-Host "------------------------------------------------------------" -ForegroundColor DarkCyan
Write-Host " KET QUA PHAN TICH VA DE XUAT SUA LOI CUA AI" -ForegroundColor Green
Write-Host "------------------------------------------------------------" -ForegroundColor DarkCyan
Write-Host "File loi:    $($analysis.file_to_patch)"
Write-Host "Mo ta loi:   $($analysis.bug_description)"
Write-Host "Huong sua:   $($analysis.suggested_fix)"
Write-Host "Doan ma goc: $($analysis.original_code_snippet)"
Write-Host "Thay the:    $($analysis.replacement_code_snippet)"
Write-Host "------------------------------------------------------------" -ForegroundColor DarkCyan

# ---------------------------------------------------------------------
# STEP 5: Interactive User Approval & Fix Application
# ---------------------------------------------------------------------
Write-Host ""
$choice = "N"
if ($AutoApprove) {
    Write-Host "Auto-approve mode is active. Automatically applying the AI proposed fix..." -ForegroundColor Green
    $choice = "Y"
} else {
    $choice = Read-Host "Ban co muon ap dung ban sua loi cua AI Assistant vao source code va chay lai regression test khong? (Y/N)"
}

if ($choice.Trim().ToUpper() -ne "Y") {
    Write-Host "Huy bo quy trinh tu sua loi theo yeu cau cua nguoi dung." -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "[STEP 5] Dang tu dong va loi (Self-Healing)..." -ForegroundColor Yellow

# Read temp file code, replace defect, and write back
$tempServiceCode = Get-Content $tempValServicePath -Raw
$patchedCode = $tempServiceCode.Replace($analysis.original_code_snippet, $analysis.replacement_code_snippet)
[System.IO.File]::WriteAllText($tempValServicePath, $patchedCode)

Write-Host "[INFO] Da va loi thanh cong vao file tam." -ForegroundColor Gray

# Compile patched code
Write-Host "Rebuilding the patched codebase..." -ForegroundColor Yellow
& $tools.Javac -encoding UTF-8 -d $tempClassesDir "$tempSrcDir\*.java"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Rebuilding patched code failed." -ForegroundColor Red
    exit 1
}
Write-Host "[INFO] Da bien dich lai codebase thanh cong." -ForegroundColor Gray

# ---------------------------------------------------------------------
# STEP 6: Run Regression Tests (Rerun Selenium validation)
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "[STEP 6] Dang khoi dong lai ung dung va chay kiem thu hoi quy (Regression Test)..." -ForegroundColor Yellow

$serverProcessPatched = Start-Process -FilePath $tools.Java -ArgumentList "-cp", "$tempClassesDir", "com.datetimechecker.App" -PassThru -NoNewWindow
Start-Sleep -Seconds 2 # Wait for boot

$regressionFailures = 0
$tsvLinesAfter = @($tsvHeader)

foreach ($tc in $testCases) {
    $dateStr = "$($tc.day)/$($tc.month)/$($tc.year)"
    Write-Host "[INFO] Dang kiem thu lai: $($tc.id) - $($tc.name) ($dateStr)... " -NoNewline
    
    $body = @{ day = $tc.day; month = $tc.month; year = $tc.year } | ConvertTo-Json
    try {
        $res = Invoke-RestMethod -Uri "http://localhost:4173/api/datetime/check" -Method Post -ContentType "application/json" -Body $body
        $actualValid = $res.valid
        
        if ($actualValid -eq $tc.expectedValid) {
            Write-Host "PASS" -ForegroundColor Green
            $tsvLinesAfter += "$($tc.id)`t$($tc.name)`t$dateStr`t$($tc.expectedValid)`t$actualValid`tPASS"
        } else {
            Write-Host "FAIL" -ForegroundColor Red
            $tsvLinesAfter += "$($tc.id)`t$($tc.name)`t$dateStr`t$($tc.expectedValid)`t$actualValid`tFAIL"
            $regressionFailures++
        }
    } catch {
        Write-Host "ERROR" -ForegroundColor Red
        $tsvLinesAfter += "$($tc.id)`t$($tc.name)`t$dateStr`t$($tc.expectedValid)`tERROR`tFAIL"
        $regressionFailures++
    }
}

$tsvLinesAfter | Out-File $failuresAfterFile -Encoding utf8 -Force
Write-Host "[INFO] Da ghi bao cao hoi quy sau khi sua vao: reports/ai-selenium-failures-after-fix.tsv" -ForegroundColor Gray

# Stop server
Stop-Process -Id $serverProcessPatched.Id -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
if ($regressionFailures -eq 0) {
    Write-Host " DEMO HOAN THANH: TU VA LOI THANH CONG (0 TESTCASE THAT BAI)" -ForegroundColor Green
} else {
    Write-Host " DEMO HOAN THANH: VAN CON $regressionFailures THAT BAI" -ForegroundColor Red
}
Write-Host "============================================================" -ForegroundColor Cyan
