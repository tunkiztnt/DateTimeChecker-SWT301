package com.datetimechecker;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.edge.EdgeDriver;
import org.openqa.selenium.edge.EdgeOptions;

import java.util.ArrayList;
import java.util.List;

public class SeleniumVisibleDemo {
    private static class TestCase {
        String id;
        String name;
        String day;
        String month;
        String year;
        boolean expectedValid;

        TestCase(String id, String name, String day, String month, String year, boolean expectedValid) {
            this.id = id;
            this.name = name;
            this.day = day;
            this.month = month;
            this.year = year;
            this.expectedValid = expectedValid;
        }
    }

    public static void main(String[] args) throws Exception {
        String targetUrl = System.getProperty("datetimechecker.url", "http://localhost:4173");

        List<TestCase> testCases = new ArrayList<>();
        testCases.add(new TestCase("TC01", "Valid normal date", "30", "5", "2026", true));
        testCases.add(new TestCase("TC02", "Leap day valid", "29", "2", "2024", true));
        testCases.add(new TestCase("TC03", "Non-leap day invalid", "29", "2", "2025", false));
        testCases.add(new TestCase("TC04", "Century leap year", "29", "2", "2000", true));
        testCases.add(new TestCase("TC05", "Century non-leap", "29", "2", "1900", false));
        testCases.add(new TestCase("TC06", "Month boundary", "31", "4", "2026", false));
        testCases.add(new TestCase("TC07", "Month upper boundary", "30", "13", "2026", false));
        testCases.add(new TestCase("TC08", "Blank input", "", "5", "2026", false));
        testCases.add(new TestCase("TC09", "Day lower boundary", "0", "5", "2026", false));
        testCases.add(new TestCase("TC10", "Month format invalid", "30", "5.5", "2026", false));

        System.out.println("============================================================");
        System.out.println(" SELENIUM WEB E2E DEMO - DateTimeChecker");
        System.out.println("============================================================");
        System.out.println("[DEMO] This test opens the real web UI, types data into the form, clicks Check,");
        System.out.println("       reads the visible result, closes the modal, and compares actual vs expected.");
        System.out.println("[DEMO] Total browser test cases: " + testCases.size());
        System.out.println("[TARGET] " + targetUrl);
        System.out.println("[TEST CASE PLAN]");
        System.out.println(" ID    NAME                         INPUT                 EXPECTED");
        for (TestCase tc : testCases) {
            System.out.printf(" %-5s %-28s %s/%s/%s              %s%n",
                    tc.id,
                    tc.name,
                    tc.day.isEmpty() ? "<blank>" : tc.day,
                    tc.month,
                    tc.year,
                    tc.expectedValid ? "VALID" : "NOT VALID");
        }
        System.out.println("Starting Selenium WebDriver (Edge)...");

        EdgeOptions options = new EdgeOptions();
        for (String arg : args) {
            if ("--headless".equals(arg)) {
                options.addArguments("--headless");
            }
        }

        WebDriver driver = new EdgeDriver(options);
        int passed = 0;

        try {
            driver.get(targetUrl);
            Thread.sleep(1000);

            for (TestCase tc : testCases) {
                System.out.println("------------------------------------------------------------");
                System.out.println("[CASE START] " + tc.id + " - " + tc.name);
                System.out.println("[INPUT] Day='" + tc.day + "', Month='" + tc.month + "', Year='" + tc.year + "'");
                System.out.println("[EXPECTED] " + (tc.expectedValid ? "VALID" : "NOT VALID"));
                System.out.println("  Step 1: Locate Day, Month, Year inputs and Clear button.");

                WebElement dayInput = driver.findElement(By.id("day"));
                WebElement monthInput = driver.findElement(By.id("month"));
                WebElement yearInput = driver.findElement(By.id("year"));
                WebElement clearBtn = driver.findElement(By.id("clearButton"));

                System.out.println("  Step 2: Clear previous data.");
                clearBtn.click();
                Thread.sleep(200);

                System.out.println("  Step 3: Type Day='" + tc.day + "'.");
                dayInput.sendKeys(tc.day);
                Thread.sleep(100);
                System.out.println("  Step 4: Type Month='" + tc.month + "'.");
                monthInput.sendKeys(tc.month);
                Thread.sleep(100);
                System.out.println("  Step 5: Type Year='" + tc.year + "'.");
                yearInput.sendKeys(tc.year);
                Thread.sleep(100);

                WebElement submitBtn = driver.findElement(By.cssSelector("button[type='submit']"));
                System.out.println("  Step 6: Click Check and wait for API/UI result.");
                submitBtn.click();
                Thread.sleep(1200);

                try {
                    WebElement modalMessage = driver.findElement(By.id("wfMbMessage"));
                    System.out.println("  Step 7: Modal message: " + modalMessage.getText());
                    WebElement okBtn = driver.findElement(By.id("wfMbOkBtn"));
                    if (okBtn.isDisplayed()) {
                        Thread.sleep(800);
                        okBtn.click();
                        Thread.sleep(400);
                    }
                } catch (Exception e) {
                    System.out.println("  Step 7: No modal message was displayed.");
                }

                WebElement resultTitle = driver.findElement(By.id("resultTitle"));
                WebElement detailGrid = driver.findElement(By.id("detailGrid"));
                boolean isActualValid = !"none".equals(detailGrid.getCssValue("display"));

                boolean isPass = isActualValid == tc.expectedValid;
                System.out.println("  Step 8: Assert visible result.");
                System.out.println("     Result title: " + resultTitle.getText());
                System.out.println("     Expected:     " + (tc.expectedValid ? "VALID" : "NOT VALID"));
                System.out.println("     Actual:       " + (isActualValid ? "VALID" : "NOT VALID"));
                if (isPass) {
                    System.out.println("     Status: PASS");
                    passed++;
                } else {
                    System.out.println("     Status: FAIL");
                }
                Thread.sleep(600);
            }

            System.out.println("\nSelenium UI demo results: " + passed + " passed, " + (testCases.size() - passed) + " failed.");
        } finally {
            boolean autoClose = false;
            for (String arg : args) {
                if ("--auto-close".equals(arg)) {
                    autoClose = true;
                }
            }
            if (autoClose) {
                driver.quit();
            } else {
                System.out.println("Browser window will stay open for inspection. Close manually or press Enter in console to quit.");
                System.in.read();
                driver.quit();
            }
        }
    }
}
