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
                System.out.println(tc.id + " RUNNING - " + tc.name);
                
                WebElement dayInput = driver.findElement(By.id("day"));
                WebElement monthInput = driver.findElement(By.id("month"));
                WebElement yearInput = driver.findElement(By.id("year"));
                WebElement clearBtn = driver.findElement(By.id("clearButton"));
                
                clearBtn.click();
                Thread.sleep(200);

                dayInput.sendKeys(tc.day);
                Thread.sleep(100);
                monthInput.sendKeys(tc.month);
                Thread.sleep(100);
                yearInput.sendKeys(tc.year);
                Thread.sleep(100);

                WebElement submitBtn = driver.findElement(By.cssSelector("button[type='submit']"));
                submitBtn.click();
                Thread.sleep(1200); // Wait for validation and display

                // Check if WinForms popup is displayed and click OK to close it
                try {
                    WebElement okBtn = driver.findElement(By.id("wfMbOkBtn"));
                    if (okBtn.isDisplayed()) {
                        Thread.sleep(800); // Let the user see the MessageBox in the browser
                        okBtn.click();
                        Thread.sleep(400); // Wait for popup to fade out
                    }
                } catch (Exception e) {
                    // No popup displayed or not clickable
                }

                WebElement resultTitle = driver.findElement(By.id("resultTitle"));
                boolean isActualValid = resultTitle.getText().contains("Ngày hợp lệ");

                boolean isPass = isActualValid == tc.expectedValid;
                System.out.println("  -> Input: [Day='" + tc.day + "', Month='" + tc.month + "', Year='" + tc.year + "']");
                System.out.println("     Result: " + (isActualValid ? "VALID" : "INVALID") + " | Expected: " + (tc.expectedValid ? "VALID" : "INVALID"));
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
