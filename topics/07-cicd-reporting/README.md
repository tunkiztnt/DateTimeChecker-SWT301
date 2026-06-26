# Topic 7: CI/CD Reporting

## Goal

Topic 7 demonstrates a polished CI/CD pipeline for `DateTimeChecker`:

1. Build the Java application
2. Start the backend
3. Run API smoke tests
4. Run Web E2E tests
5. Run Visual Regression tests
6. Generate Allure + Playwright reports
7. Create a deployment-ready release ZIP

## Local Demo

Run:

```bat
topics\07-cicd-reporting\run.bat
```

If you want the Allure web report to open automatically after a successful run:

```bat
topics\07-cicd-reporting\run.bat --open-report
```

## GitHub Actions Demo

Workflow file:

```text
.github/workflows/topic7-cicd.yml
```

The workflow runs on `windows-latest` so local rendering and CI rendering stay aligned for the visual-regression stage.

By default, the GitHub Actions workflow calls:

```powershell
.\topics\07-cicd-reporting\run.ps1 -CiMode
```

The workflow does not decide which test groups are enabled. The source of truth is the `StageStatus` block near the top of:

```text
topics/07-cicd-reporting/run.ps1
```

Default demo setup:

```powershell
$StageStatus = [ordered]@{
    ApiSmoke = 'ON'
    WebE2E = 'ON'
    VisualRegression = 'OFF'
    AllureReport = 'ON'
    ReleasePackage = 'ON'
}
```

This keeps the CI pipeline fast and stable by skipping visual regression by default. The summary still records `Visual Regression Tests` as `SKIPPED`.

To run the full pipeline locally, including visual regression, use:

```powershell
.\topics\07-cicd-reporting\run.ps1 -RunVisual
```

To temporarily override a stage without editing the file:

```powershell
.\topics\07-cicd-reporting\run.ps1 -SkipApi
.\topics\07-cicd-reporting\run.ps1 -SkipWeb
.\topics\07-cicd-reporting\run.ps1 -RunVisual
.\topics\07-cicd-reporting\run.ps1 -SkipReport
.\topics\07-cicd-reporting\run.ps1 -SkipPackage
```

For a classroom demo, edit `StageStatus` when you want a clear permanent scenario, and use `-Run...` / `-Skip...` switches only for quick one-time runs.

## Key Artifacts

- Summary: `topics/reports/topic07-cicd/ci-summary.md`
- Playwright HTML report: `playwright-report`
- Allure HTML report: `allure-report`
- Visual current images: `topics/05-visual-regression/current-run-images`
- Visual diff images: `topics/05-visual-regression/diff-images`
- Deployment package: `topics/reports/topic07-cicd/DateTimeChecker-release.zip`

## Why This Demo Is Stable

- Uses local Windows fonts for deterministic visual rendering
- Runs only stable CI-suitable suites in the main pipeline
- Keeps visual artifacts even when tests fail
- Generates one clear summary file for presentation
- Produces a real release ZIP as the CD output
