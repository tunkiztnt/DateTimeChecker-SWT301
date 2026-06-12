# Topic 8: CI/CD & Reporting - Tích hợp liên tục và báo cáo

## Dùng để làm gì?

CI/CD & Reporting mô phỏng pipeline kiểm thử tự động cục bộ cho DateTimeChecker. Topic này gom nhiều tầng test vào một luồng để chứng minh code có thể được build, test và tổng hợp kết quả theo quy trình gần giống dự án thực tế.

## Vai trò và ý nghĩa

- Tạo quy trình kiểm tra tự động trước khi nhóm nộp bài hoặc quay demo.
- Gom kết quả Unit, API, Web E2E, Mobile, Performance, Visual và AI-Assisted Testing.
- Cho thấy cách team QA báo cáo chất lượng phần mềm theo stage PASS/FAIL.

## Thành phần chính

- CI simulation runner: `Topic 8 - CI CD and Reporting/run-ci-simulation.bat`
- Root all-topic runner: `run-all-topics.bat`
- Báo cáo API: `reports/api-testing-report.tsv`
- Báo cáo Mobile: `reports/mobile-testing-report.txt`
- Báo cáo Performance: `reports/performance-report.txt`
- Playwright report: `reports/playwright-report/`

## Cách chạy

Chạy riêng Topic 8:

```powershell
.\Topic 8 - CI CD and Reporting\run-ci-simulation.bat
```

Chạy toàn bộ 8 topic:

```powershell
.\run-all-topics.bat
```

## Luồng pipeline mô phỏng

1. Stage 1: Build Java source.
2. Stage 2: Unit Testing cho Java và JavaScript.
3. Stage 3: API Testing bằng Playwright và PowerShell.
4. Stage 4: Web E2E bằng Playwright/Selenium.
5. Stage 5: Mobile Testing hoặc fallback simulation.
6. Stage 6: Performance Testing bằng Autocannon.
7. Stage 7: Visual Regression bằng Playwright screenshots.
8. Stage 8: AI-Assisted Testing offline/self-healing demo.
9. Summary: tổng hợp số stage PASS/FAIL/SKIPPED.

## Kết quả mong đợi

- CMD hiển thị từng stage đang chạy.
- Nếu một stage fail, các stage sau có thể bị skip để mô phỏng quality gate.
- Cuối pipeline có `PIPELINE SUMMARY`.
- Các báo cáo chi tiết nằm trong thư mục `reports/`.

## Gợi ý lời demo

"Topic 8 là lớp tổng hợp. Thay vì chạy từng topic rời rạc, pipeline mô phỏng CI/CD giúp team nhìn trạng thái chất lượng toàn dự án qua từng stage và biết lỗi nằm ở tầng nào."
