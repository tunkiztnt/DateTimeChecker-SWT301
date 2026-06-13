param(
    [string]$ApiKey,
    [switch]$OfflineSample,
    [string]$OutputFile = "$PSScriptRoot\..\reports\ai-generated-testcases.json",
    [string]$Prompt = "Create 10 JSON test cases for DateTimeChecker covering leap year, month boundary, invalid format, and invalid range."
)

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

. "$PSScriptRoot\gemini-common.ps1"

function Write-Utf8NoBomFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Get-JsonArrayText {
    param([string]$Text)

    if (-not $Text) {
        return $null
    }

    $trimmed = $Text.Trim()
    if ($trimmed.StartsWith('```')) {
        $trimmed = ($trimmed -replace '^```json\s*', '') -replace '^```\s*', ''
        $trimmed = ($trimmed -replace '\s*```$', '')
    }

    $match = [regex]::Match($trimmed, '\[[\s\S]*\]')
    if ($match.Success) {
        return $match.Value
    }

    return $null
}

function Get-RequestedCaseCount {
    param([string]$PromptText)

    $defaultCount = 10
    if ([string]::IsNullOrWhiteSpace($PromptText)) {
        return $defaultCount
    }

    $match = [regex]::Match($PromptText, '(?<!\d)(\d{1,2})(?!\d)')
    if ($match.Success) {
        $count = [int]$match.Groups[1].Value
        if ($count -lt 1) { return $defaultCount }
        if ($count -gt 30) { return 30 }
        return $count
    }

    return $defaultCount
}

function Get-PromptTopics {
    param([string]$PromptText)

    $promptLower = if ($PromptText) { $PromptText.ToLowerInvariant() } else { "" }
    $topics = @()

    if ($promptLower -match "clear") { $topics += "clear" }
    if ($promptLower -match "format|invalid format|chuoi|string|text|empty") { $topics += "format" }
    if ($promptLower -match "leap|nhuan|february 29|29/2") { $topics += "leap" }
    if ($promptLower -match "month|april|february|30-day|31-day|biên tháng|tháng") { $topics += "month" }
    if ($promptLower -match "min|max|boundary|range|0|32|13|999|3001|minimum|maximum|upper|lower") {
        $topics += "range"
        $topics += "boundary"
    }

    return @($topics | Select-Object -Unique)
}

function Get-CaseTopics {
    param([object]$Case)

    $topics = @()
    $day = [string]$Case.day
    $month = [string]$Case.month
    $year = [string]$Case.year
    $name = ([string]$Case.name).ToLowerInvariant()
    $reason = ([string]$Case.reason).ToLowerInvariant()

    if ([string]::IsNullOrWhiteSpace($day) -or [string]::IsNullOrWhiteSpace($month) -or [string]::IsNullOrWhiteSpace($year)) {
        $topics += "format"
    }

    $numericDay = $day -match '^\d+$'
    $numericMonth = $month -match '^\d+$'
    $numericYear = $year -match '^\d+$'

    if (-not $numericDay -or -not $numericMonth -or -not $numericYear) {
        $topics += "format"
    }

    if ($numericDay -and $numericMonth -and $numericYear) {
        $dayNumber = [int]$day
        $monthNumber = [int]$month
        $yearNumber = [int]$year

        if ($dayNumber -lt 1 -or $dayNumber -gt 31 -or $monthNumber -lt 1 -or $monthNumber -gt 12 -or $yearNumber -lt 1000 -or $yearNumber -gt 3000) {
            $topics += "range"
        }

        if (
            ($dayNumber -eq 1 -and $monthNumber -eq 1 -and $yearNumber -eq 1000) -or
            ($dayNumber -eq 31 -and $monthNumber -eq 12 -and $yearNumber -eq 3000)
        ) {
            $topics += "boundary"
        }

        if (($monthNumber -eq 2 -and $dayNumber -eq 29) -or $name.Contains("leap") -or $reason.Contains("leap")) {
            $topics += "leap"
        }

        if (
            ($monthNumber -eq 4 -and $dayNumber -gt 30) -or
            ($monthNumber -eq 2 -and $dayNumber -gt 29) -or
            $name.Contains("april") -or
            $name.Contains("february") -or
            $reason.Contains("april") -or
            $reason.Contains("february")
        ) {
            $topics += "month"
        }
    }

    return @($topics | Select-Object -Unique)
}

function Normalize-Testcases {
    param([object[]]$Cases)

    $normalized = @()
    $index = 1

    foreach ($case in $Cases) {
        $expectedResult = [string]$case.expectedResult
        if ([string]::IsNullOrWhiteSpace($expectedResult)) {
            if ([bool]$case.expectedValid) {
                $expectedResult = "VALID"
            } else {
                $expectedResult = "INVALID"
            }
        }

        $caseId = "AI{0:D2}" -f $index
        if (-not [string]::IsNullOrWhiteSpace([string]$case.id)) {
            $caseId = [string]$case.id
        }

        $caseName = "AI generated case $index"
        if (-not [string]::IsNullOrWhiteSpace([string]$case.name)) {
            $caseName = [string]$case.name
        }

        $normalized += [PSCustomObject]@{
            id = $caseId
            name = $caseName
            testType = if (-not [string]::IsNullOrWhiteSpace([string]$case.testType)) { [string]$case.testType } elseif (-not [string]::IsNullOrWhiteSpace([string]$case.topic)) { [string]$case.topic } else { "" }
            day = [string]$case.day
            month = [string]$case.month
            year = [string]$case.year
            expectedValid = [bool]$case.expectedValid
            expectedResult = $expectedResult
            expectedDisplay = [string]$case.expectedDisplay
            expectedMessageIncludes = [string]$case.expectedMessageIncludes
            reason = [string]$case.reason
        }

        $index++
    }

    return $normalized
}

function Convert-ExactAiTestcases {
    param(
        [object[]]$Cases,
        [int]$RequestedCount
    )

    if (-not $Cases -or @($Cases).Count -eq 0) {
        throw "Gemini returned no test cases."
    }

    $actualCount = @($Cases).Count
    if ($actualCount -ne $RequestedCount) {
        throw "Gemini returned $actualCount test cases, but the prompt requested exactly $RequestedCount."
    }

    $allowedExpectedResults = @("VALID", "INVALID", "ERROR")
    $prepared = @()
    $index = 1

    foreach ($case in $Cases) {
        if ($null -eq $case) {
            throw "Gemini returned a null testcase at position $index."
        }

        $propertyNames = @($case.PSObject.Properties.Name)
        $hasId = $propertyNames -contains 'id'
        $hasName = $propertyNames -contains 'name'
        $hasTestType = $propertyNames -contains 'testType'
        $hasDay = $propertyNames -contains 'day'
        $hasMonth = $propertyNames -contains 'month'
        $hasYear = $propertyNames -contains 'year'
        $hasExpectedValid = $propertyNames -contains 'expectedValid'
        $hasExpectedResult = $propertyNames -contains 'expectedResult'
        $hasReason = $propertyNames -contains 'reason'

        $id = [string]$case.id
        $name = [string]$case.name
        $testType = if ($hasTestType -and $null -ne $case.testType) { [string]$case.testType } else { "" }
        $day = if ($hasDay -and $null -ne $case.day) { [string]$case.day } else { "" }
        $month = if ($hasMonth -and $null -ne $case.month) { [string]$case.month } else { "" }
        $year = if ($hasYear -and $null -ne $case.year) { [string]$case.year } else { "" }
        $expectedResult = ([string]$case.expectedResult).ToUpperInvariant()
        $reason = [string]$case.reason

        if (-not $hasId -or [string]::IsNullOrWhiteSpace($id)) {
            throw "Gemini testcase #$index is missing 'id'."
        }
        if (-not $hasName -or [string]::IsNullOrWhiteSpace($name)) {
            throw "Gemini testcase '$id' is missing 'name'."
        }
        if (-not $hasDay) {
            throw "Gemini testcase '$id' is missing 'day'. Use an empty string if this is an empty-input testcase."
        }
        if (-not $hasMonth) {
            throw "Gemini testcase '$id' is missing 'month'. Use an empty string if this is an empty-input testcase."
        }
        if (-not $hasYear) {
            throw "Gemini testcase '$id' is missing 'year'. Use an empty string if this is an empty-input testcase."
        }
        if (-not $hasExpectedResult -or $allowedExpectedResults -notcontains $expectedResult) {
            throw "Gemini testcase '$id' has invalid expectedResult '$($case.expectedResult)'."
        }
        if (-not $hasExpectedValid -or $null -eq $case.expectedValid -or $case.expectedValid -isnot [bool]) {
            throw "Gemini testcase '$id' must include boolean 'expectedValid'."
        }
        if (-not $hasReason -or [string]::IsNullOrWhiteSpace($reason)) {
            throw "Gemini testcase '$id' is missing 'reason'."
        }

        $prepared += [PSCustomObject]@{
            id = $id
            name = $name
            testType = $testType
            day = $day
            month = $month
            year = $year
            expectedValid = [bool]$case.expectedValid
            expectedResult = $expectedResult
            expectedDisplay = if ($null -eq $case.expectedDisplay) { $null } else { [string]$case.expectedDisplay }
            expectedMessageIncludes = if ($null -eq $case.expectedMessageIncludes) { $null } else { [string]$case.expectedMessageIncludes }
            reason = $reason
        }

        $index++
    }

    return $prepared
}

function Complete-TestcaseSet {
    param(
        [object[]]$Cases,
        [string]$PromptText,
        [int]$RequestedCount
    )

    $working = @($Cases)
    $promptTopics = Get-PromptTopics -PromptText $PromptText

    if ($promptTopics.Count -gt 0) {
        $filtered = @()
        foreach ($case in $working) {
            $caseTopics = Get-CaseTopics -Case $case
            $matched = $caseTopics | Where-Object { $promptTopics -contains $_ }
            if ($matched.Count -gt 0) {
                $filtered += $case
            }
        }
        if ($filtered.Count -gt 0) {
            $working = $filtered
        }
    }

    if ($working.Count -gt $RequestedCount) {
        return @($working | Select-Object -First $RequestedCount)
    }

    if ($working.Count -lt $RequestedCount) {
        $fallback = Get-OfflineSampleCases -PromptText $PromptText -RequestedCount $RequestedCount
        foreach ($candidate in $fallback) {
            if ($working.Count -ge $RequestedCount) { break }
            $exists = $working | Where-Object {
                $_.name -eq $candidate.name -or
                (
                    [string]$_.day -eq [string]$candidate.day -and
                    [string]$_.month -eq [string]$candidate.month -and
                    [string]$_.year -eq [string]$candidate.year
                )
            }
            if (-not $exists) {
                $working += $candidate
            }
        }
    }

    return @($working | Select-Object -First $RequestedCount)
}

function Get-OfflineSampleCases {
    param(
        [string]$PromptText,
        [int]$RequestedCount
    )

    $promptLower = if ($PromptText) { $PromptText.ToLowerInvariant() } else { "" }
    $catalog = @(
        [PSCustomObject]@{ name="Valid standard date"; topic="baseline"; day="30"; month="5"; year="2026"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="30/05/2026"; expectedMessageIncludes=$null; reason="A standard valid date within the normal range." },
        [PSCustomObject]@{ name="Valid first day of year"; topic="baseline"; day="1"; month="1"; year="2023"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="01/01/2023"; expectedMessageIncludes=$null; reason="The first valid day of the year should pass." },
        [PSCustomObject]@{ name="Valid end of year"; topic="baseline"; day="31"; month="12"; year="2023"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="31/12/2023"; expectedMessageIncludes=$null; reason="The last day of the year should pass." },
        [PSCustomObject]@{ name="Valid leap-year date"; topic="leap"; day="29"; month="2"; year="2024"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="29/02/2024"; expectedMessageIncludes=$null; reason="2024 is a leap year." },
        [PSCustomObject]@{ name="Invalid non-leap-year date"; topic="leap"; day="29"; month="2"; year="2025"; expectedValid=$false; expectedResult="INVALID"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="2025 is not a leap year." },
        [PSCustomObject]@{ name="Leap year divisible by 400"; topic="leap"; day="29"; month="2"; year="2000"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="29/02/2000"; expectedMessageIncludes=$null; reason="A year divisible by 400 is leap." },
        [PSCustomObject]@{ name="Century year not divisible by 400"; topic="leap"; day="29"; month="2"; year="1900"; expectedValid=$false; expectedResult="INVALID"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="1900 is not a leap year." },
        [PSCustomObject]@{ name="Another valid leap year"; topic="leap"; day="29"; month="2"; year="2016"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="29/02/2016"; expectedMessageIncludes=$null; reason="2016 is a leap year." },
        [PSCustomObject]@{ name="Another invalid non-leap year"; topic="leap"; day="29"; month="2"; year="2019"; expectedValid=$false; expectedResult="INVALID"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="2019 is not a leap year." },
        [PSCustomObject]@{ name="Leap year 2028"; topic="leap"; day="29"; month="2"; year="2028"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="29/02/2028"; expectedMessageIncludes=$null; reason="2028 is a leap year." },
        [PSCustomObject]@{ name="Common year 2027"; topic="leap"; day="29"; month="2"; year="2027"; expectedValid=$false; expectedResult="INVALID"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="2027 is not a leap year." },
        [PSCustomObject]@{ name="Leap century year 2400"; topic="leap"; day="29"; month="2"; year="2400"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="29/02/2400"; expectedMessageIncludes=$null; reason="2400 is divisible by 400." },
        [PSCustomObject]@{ name="Non-leap century year 2100"; topic="leap"; day="29"; month="2"; year="2100"; expectedValid=$false; expectedResult="INVALID"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="2100 is not divisible by 400." },
        [PSCustomObject]@{ name="February 28 in common year"; topic="leap"; day="28"; month="2"; year="2023"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="28/02/2023"; expectedMessageIncludes=$null; reason="February 28 is valid in a common year." },
        [PSCustomObject]@{ name="February 28 in leap year"; topic="leap"; day="28"; month="2"; year="2024"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="28/02/2024"; expectedMessageIncludes=$null; reason="February 28 is valid in a leap year." },
        [PSCustomObject]@{ name="March 1 after common February"; topic="leap"; day="1"; month="3"; year="2023"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="01/03/2023"; expectedMessageIncludes=$null; reason="March 1 is valid after a common February." },
        [PSCustomObject]@{ name="March 1 after leap February"; topic="leap"; day="1"; month="3"; year="2024"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="01/03/2024"; expectedMessageIncludes=$null; reason="March 1 is valid after leap day." },
        [PSCustomObject]@{ name="February 30 in leap year"; topic="leap"; day="30"; month="2"; year="2024"; expectedValid=$false; expectedResult="INVALID"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Leap years still do not allow February 30." },
        [PSCustomObject]@{ name="February 31 in leap year"; topic="leap"; day="31"; month="2"; year="2024"; expectedValid=$false; expectedResult="INVALID"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Leap years still do not allow February 31." },
        [PSCustomObject]@{ name="February 29 in 1800"; topic="leap"; day="29"; month="2"; year="1800"; expectedValid=$false; expectedResult="INVALID"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="1800 is not a leap century year." },
        [PSCustomObject]@{ name="February 29 in 1600"; topic="leap"; day="29"; month="2"; year="1600"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="29/02/1600"; expectedMessageIncludes=$null; reason="1600 is a leap century year." },
        [PSCustomObject]@{ name="Invalid day for April"; topic="month"; day="31"; month="4"; year="2026"; expectedValid=$false; expectedResult="INVALID"; expectedDisplay=$null; expectedMessageIncludes="30"; reason="April has only 30 days." },
        [PSCustomObject]@{ name="Invalid February 30"; topic="month"; day="30"; month="2"; year="2024"; expectedValid=$false; expectedResult="INVALID"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="February never has 30 days." },
        [PSCustomObject]@{ name="Valid 30-day month end"; topic="month"; day="30"; month="9"; year="2023"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="30/09/2023"; expectedMessageIncludes=$null; reason="September 30 is valid." },
        [PSCustomObject]@{ name="Out-of-range day zero"; topic="range"; day="0"; month="5"; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Day zero is outside the allowed range." },
        [PSCustomObject]@{ name="Out-of-range day 32"; topic="range"; day="32"; month="1"; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Day 32 is outside the allowed range." },
        [PSCustomObject]@{ name="Out-of-range month zero"; topic="range"; day="15"; month="0"; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Month zero is outside the allowed range." },
        [PSCustomObject]@{ name="Out-of-range month 13"; topic="range"; day="15"; month="13"; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Month 13 is outside the allowed range." },
        [PSCustomObject]@{ name="Year below minimum"; topic="range"; day="15"; month="6"; year="999"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Year 999 is below the minimum supported year." },
        [PSCustomObject]@{ name="Year above maximum"; topic="range"; day="15"; month="6"; year="3001"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Year 3001 is above the maximum supported year." },
        [PSCustomObject]@{ name="Minimum valid boundary"; topic="boundary"; day="1"; month="1"; year="1000"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="01/01/1000"; expectedMessageIncludes=$null; reason="Minimum supported values should pass." },
        [PSCustomObject]@{ name="Maximum valid boundary"; topic="boundary"; day="31"; month="12"; year="3000"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="31/12/3000"; expectedMessageIncludes=$null; reason="Maximum supported values should pass." },
        [PSCustomObject]@{ name="Non-numeric day input"; topic="format"; day="abc"; month="5"; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Text input for day should fail format validation." },
        [PSCustomObject]@{ name="Non-numeric month input"; topic="format"; day="15"; month="xyz"; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Text input for month should fail format validation." },
        [PSCustomObject]@{ name="Non-numeric year input"; topic="format"; day="15"; month="6"; year="year"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Text input for year should fail format validation." },
        [PSCustomObject]@{ name="Empty day input"; topic="format"; day=""; month="6"; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Missing day should fail validation." },
        [PSCustomObject]@{ name="Empty month input"; topic="format"; day="15"; month=""; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Missing month should fail validation." },
        [PSCustomObject]@{ name="Empty year input"; topic="format"; day="15"; month="6"; year=""; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Missing year should fail validation." },
        [PSCustomObject]@{ name="Day with spaces"; topic="format"; day="  "; month="6"; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Blank spaces in day should fail validation." },
        [PSCustomObject]@{ name="Month with spaces"; topic="format"; day="15"; month="   "; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Blank spaces in month should fail validation." },
        [PSCustomObject]@{ name="Year with spaces"; topic="format"; day="15"; month="6"; year="   "; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Blank spaces in year should fail validation." },
        [PSCustomObject]@{ name="Decimal day input"; topic="format"; day="1.5"; month="6"; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Decimal day should fail integer validation." },
        [PSCustomObject]@{ name="Decimal month input"; topic="format"; day="15"; month="6.7"; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Decimal month should fail integer validation." },
        [PSCustomObject]@{ name="Decimal year input"; topic="format"; day="15"; month="6"; year="2026.1"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Decimal year should fail integer validation." },
        [PSCustomObject]@{ name="Special characters in day"; topic="format"; day="@!"; month="6"; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Special characters in day should fail validation." },
        [PSCustomObject]@{ name="Special characters in month"; topic="format"; day="15"; month="#$"; year="2026"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Special characters in month should fail validation." },
        [PSCustomObject]@{ name="Special characters in year"; topic="format"; day="15"; month="6"; year="****"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Special characters in year should fail validation." },
        [PSCustomObject]@{ name="Alpha-numeric year"; topic="format"; day="15"; month="6"; year="20A6"; expectedValid=$false; expectedResult="ERROR"; expectedDisplay=$null; expectedMessageIncludes=$null; reason="Mixed text and numbers in year should fail validation." },
        [PSCustomObject]@{ name="Pre-clear valid input"; topic="clear"; day="15"; month="6"; year="2026"; expectedValid=$true; expectedResult="VALID"; expectedDisplay="15/06/2026"; expectedMessageIncludes=$null; reason="Baseline valid case before discussing clear behavior." }
    )

    $topicKeywords = @()
    if ($promptLower -match "clear") { $topicKeywords += "clear" }
    if ($promptLower -match "format|invalid format|chuoi|string|text|empty") { $topicKeywords += "format" }
    if ($promptLower -match "leap|nhuan") { $topicKeywords += "leap" }
    if ($promptLower -match "month|boundary|april") { $topicKeywords += "month" }
    if ($promptLower -match "min|max|boundary|range|0|32|13|999|3001") { $topicKeywords += "range"; $topicKeywords += "boundary" }

    $selected = @()
    if ($topicKeywords.Count -gt 0) {
        foreach ($case in $catalog) {
            if ($topicKeywords -contains $case.topic) {
                $selected += $case
            }
        }
    }

    if ($selected.Count -eq 0) {
        $selected = @($catalog)
    }

    $candidatePool = @($catalog)
    if ($topicKeywords.Count -gt 0) {
        $candidatePool = @($catalog | Where-Object { $topicKeywords -contains $_.topic })
    }

    foreach ($case in $candidatePool) {
        if ($selected.Count -ge $RequestedCount) { break }
        $exists = $selected | Where-Object { $_.name -eq $case.name }
        if (-not $exists) {
            $selected += $case
        }
    }

    return $selected | Select-Object -First $RequestedCount
}

$outputDirectory = Split-Path -Parent $OutputFile
if (-not (Test-Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$requestedCount = Get-RequestedCaseCount -PromptText $Prompt

if ($OfflineSample) {
    $cases = Get-OfflineSampleCases -PromptText $Prompt -RequestedCount $requestedCount
    $cases = Complete-TestcaseSet -Cases $cases -PromptText $Prompt -RequestedCount $requestedCount
    $normalized = Normalize-Testcases -Cases $cases
    $jsonOutput = $normalized | ConvertTo-Json -Depth 6
    Write-Utf8NoBomFile -Path $OutputFile -Content $jsonOutput
    Write-Host "[OFFLINE] Exported $($normalized.Count) AI sample test cases to: $OutputFile" -ForegroundColor Green
    exit 0
}

if (-not $ApiKey) {
    $ApiKey = Get-GeminiApiKey
}

$systemInstruction = @"
You are a software testing assistant for DateTimeChecker.
Return only a JSON array.
Each item must use this schema:
[
  {
    "id": "AI01",
    "name": "short English testcase name",
    "testType": "Boundary",
    "day": "30",
    "month": "5",
    "year": "2026",
    "expectedValid": true,
    "expectedResult": "VALID",
    "expectedDisplay": "30/05/2026",
    "expectedMessageIncludes": null,
    "reason": "short explanation"
  }
]

Rules:
- Return exactly $requestedCount cases.
- Use only English text.
- Every testcase must include all keys: id, name, testType, day, month, year, expectedValid, expectedResult, expectedDisplay, expectedMessageIncludes, reason.
- If a testcase is for empty input, keep the key and use an empty string "" for day, month, or year. Never omit the key.
- expectedResult must be one of VALID, INVALID, ERROR.
- For invalid dates that still parse, use INVALID.
- For malformed or out-of-range values, use ERROR when appropriate.
- Return raw JSON only. No markdown fences. No explanation outside JSON.
"@

$response = Invoke-GeminiPrompt -apiKey $ApiKey -systemInstruction $systemInstruction -userPrompt $Prompt
$jsonText = Get-JsonArrayText -Text $response

if (-not $jsonText) {
    Write-Host "[ERROR] Gemini did not return a JSON array that could be parsed." -ForegroundColor Red
    exit 1
}

try {
    $cases = $jsonText | ConvertFrom-Json
    if (-not $cases -or $cases.Count -eq 0) {
        throw "No test cases were returned."
    }

    $exactCases = Convert-ExactAiTestcases -Cases $cases -RequestedCount $requestedCount
    $jsonOutput = $exactCases | ConvertTo-Json -Depth 6
    Write-Utf8NoBomFile -Path $OutputFile -Content $jsonOutput
    Write-Host "[SUCCESS] Exported $($exactCases.Count) Gemini-generated test cases exactly as returned to: $OutputFile" -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "[ERROR] Failed to parse AI-generated JSON test cases: $_" -ForegroundColor Red
    exit 1
}
