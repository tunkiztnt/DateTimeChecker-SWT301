package com.datetimechecker;

import com.datetimechecker.DateTimeValidationService.DateTimeCheckRequest;
import com.datetimechecker.DateTimeValidationService.DateTimeCheckResult;

import java.util.ArrayList;
import java.util.List;

public final class DateTimeValidationServiceTest {
    private static final DateTimeValidationService VALIDATOR = new DateTimeValidationService();
    private static final List<String> FAILURES = new ArrayList<String>();

    private DateTimeValidationServiceTest() {
    }

    public static void main(String[] args) {
        run("Accepts a valid date", new TestCase() {
            @Override
            public void execute() {
                assertTrue(validate().valid, "Expected a valid date.");
            }
        });

        run("Rejects a day that does not exist in the selected month", new TestCase() {
            @Override
            public void execute() {
                DateTimeCheckResult result = validate("31", "4", "2026");
                assertTrue(!result.valid, "Expected April 31 to be invalid.");
                assertTrue(contains(result, "chỉ có 30 ngày"), "Expected a month length error.");
            }
        });

        run("Accepts February 29 only in a leap year", new TestCase() {
            @Override
            public void execute() {
                assertTrue(validate("29", "2", "2024").valid, "Expected February 29, 2024 to be valid.");
                assertTrue(!validate("29", "2", "2025").valid, "Expected February 29, 2025 to be invalid.");
            }
        });

        run("Rejects invalid date ranges", new TestCase() {
            @Override
            public void execute() {
                assertTrue(!validate("0", "5", "2026").valid, "Expected day 0 to be invalid.");
                assertTrue(!validate("30", "13", "2026").valid, "Expected month 13 to be invalid.");
                assertTrue(!validate("30", "5", "999").valid, "Expected year 999 to be invalid.");
                assertTrue(!validate("30", "5", "3001").valid, "Expected year 3001 to be invalid.");
            }
        });

        run("Rejects blank and decimal values", new TestCase() {
            @Override
            public void execute() {
                assertTrue(!validate("", "5", "2026").valid, "Expected a blank day to be invalid.");
                assertTrue(!validate("30", "5.5", "2026").valid, "Expected a decimal month to be invalid.");
            }
        });

        run("Describes a valid date", new TestCase() {
            @Override
            public void execute() {
                DateTimeCheckResult result = validate();
                assertEquals("30/05/2026", result.details.display, "Expected a formatted date.");
                assertEquals("Không", result.details.leapYear, "Expected 2026 not to be a leap year.");
                assertEquals("31", result.details.monthDays, "Expected May to have 31 days.");
            }
        });

        run("Handles century leap-year rules", new TestCase() {
            @Override
            public void execute() {
                assertTrue(validate("29", "2", "2000").valid, "Expected year 2000 to be a leap year.");
                assertTrue(!validate("29", "2", "1900").valid, "Expected year 1900 not to be a leap year.");
            }
        });

        // Run new Boundary Value Analysis tests programmatically
        final BoundaryValueAnalysis bva = new BoundaryValueAnalysis();
        
        run("BVA: day=1, month=1, year=1000 -> VALID (absolute minimum)", new TestCase() {
            @Override public void execute() { bva.testAbsoluteMinimumValid(); }
        });
        run("BVA: day=0, month=1, year=1000 -> ERROR (Day out of range)", new TestCase() {
            @Override public void execute() { bva.testDayZeroInvalid(); }
        });
        run("BVA: day=1, month=0, year=1000 -> ERROR (Month out of range)", new TestCase() {
            @Override public void execute() { bva.testMonthZeroInvalid(); }
        });
        run("BVA: day=1, month=1, year=999 -> ERROR (Year out of range)", new TestCase() {
            @Override public void execute() { bva.testYearBelowRangeInvalid(); }
        });
        run("BVA: day=31, month=12, year=3000 -> VALID (absolute maximum)", new TestCase() {
            @Override public void execute() { bva.testAbsoluteMaximumValid(); }
        });
        run("BVA: day=32, month=12, year=3000 -> ERROR (Day out of range)", new TestCase() {
            @Override public void execute() { bva.testDayAboveRangeInvalid(); }
        });
        run("BVA: day=31, month=13, year=3000 -> ERROR (Month out of range)", new TestCase() {
            @Override public void execute() { bva.testMonthAboveRangeInvalid(); }
        });
        run("BVA: day=31, month=12, year=3001 -> ERROR (Year out of range)", new TestCase() {
            @Override public void execute() { bva.testYearAboveRangeInvalid(); }
        });
        run("BVA: day=29, month=2, year=2000 -> VALID (divisible by 400)", new TestCase() {
            @Override public void execute() { bva.testLeapYearDivBy400(); }
        });
        run("BVA: day=29, month=2, year=1900 -> INVALID (divisible by 100, not 400)", new TestCase() {
            @Override public void execute() { bva.testNonLeapYearDivBy100(); }
        });
        run("BVA: day=29, month=2, year=2024 -> VALID (divisible by 4, not 100)", new TestCase() {
            @Override public void execute() { bva.testLeapYearDivBy4(); }
        });
        run("BVA: day=29, month=2, year=2023 -> INVALID (not divisible by 4)", new TestCase() {
            @Override public void execute() { bva.testNonLeapYearNotDivBy4(); }
        });
        run("BVA: day=30, month=2, year=2024 -> INVALID (no Feb 30 ever)", new TestCase() {
            @Override public void execute() { bva.testFeb30NeverValid(); }
        });
        run("BVA: day=30, month=4, year=2023 -> VALID (Month-end)", new TestCase() {
            @Override public void execute() { bva.testMonthEndBoundaries("30", "4", "2023", true); }
        });
        run("BVA: day=31, month=4, year=2023 -> INVALID (Month-end)", new TestCase() {
            @Override public void execute() { bva.testMonthEndBoundaries("31", "4", "2023", false); }
        });
        run("BVA: day=30, month=6, year=2023 -> VALID (Month-end)", new TestCase() {
            @Override public void execute() { bva.testMonthEndBoundaries("30", "6", "2023", true); }
        });
        run("BVA: day=31, month=6, year=2023 -> INVALID (Month-end)", new TestCase() {
            @Override public void execute() { bva.testMonthEndBoundaries("31", "6", "2023", false); }
        });
        run("BVA: day=30, month=9, year=2023 -> VALID (Month-end)", new TestCase() {
            @Override public void execute() { bva.testMonthEndBoundaries("30", "9", "2023", true); }
        });
        run("BVA: day=31, month=9, year=2023 -> INVALID (Month-end)", new TestCase() {
            @Override public void execute() { bva.testMonthEndBoundaries("31", "9", "2023", false); }
        });
        run("BVA: day=30, month=11, year=2023 -> VALID (Month-end)", new TestCase() {
            @Override public void execute() { bva.testMonthEndBoundaries("30", "11", "2023", true); }
        });
        run("BVA: day=31, month=11, year=2023 -> INVALID (Month-end)", new TestCase() {
            @Override public void execute() { bva.testMonthEndBoundaries("31", "11", "2023", false); }
        });
        run("BVA: day=abc -> ERROR (not a number)", new TestCase() {
            @Override public void execute() { bva.testDayNotANumber(); }
        });
        run("BVA: month=5.5 -> ERROR (not a number)", new TestCase() {
            @Override public void execute() { bva.testMonthDecimal(); }
        });
        run("BVA: year='' -> ERROR (not a number)", new TestCase() {
            @Override public void execute() { bva.testYearEmpty(); }
        });
        run("BVA: day=-1 -> ERROR (out of range)", new TestCase() {
            @Override public void execute() { bva.testDayNegativeOutOfRange(); }
        });

        System.out.println();
        if (FAILURES.isEmpty()) {
            System.out.println("All Java validation tests passed.");
            return;
        }

        System.err.println(FAILURES.size() + " test(s) failed.");
        System.exit(1);
    }

    private static DateTimeCheckResult validate() {
        return validate("30", "5", "2026");
    }

    private static DateTimeCheckResult validate(
            String day,
            String month,
            String year) {
        DateTimeCheckResult result = VALIDATOR.validate(new DateTimeCheckRequest(day, month, year));
        System.out.println("  -> Input: [Day='" + day + "', Month='" + month + "', Year='" + year
                + "'] | Result: " + result.result + ", valid=" + result.valid
                + ", errorCount=" + result.errors.size());
        return result;
    }

    private static boolean contains(DateTimeCheckResult result, String text) {
        for (String error : result.errors) {
            if (error.contains(text)) return true;
        }
        return false;
    }

    private static void run(String name, TestCase test) {
        try {
            test.execute();
            System.out.println("PASS " + name);
        } catch (RuntimeException exception) {
            FAILURES.add(name);
            System.err.println("FAIL " + name + ": " + exception.getMessage());
        }
    }

    private static void assertTrue(boolean condition, String message) {
        if (!condition) throw new IllegalStateException(message);
    }

    private static void assertEquals(String expected, String actual, String message) {
        if (!expected.equals(actual)) {
            throw new IllegalStateException(message + " Expected: " + expected + ", actual: " + actual);
        }
    }

    private interface TestCase {
        void execute();
    }

    @org.junit.jupiter.api.Nested
    @org.junit.jupiter.api.DisplayName("Boundary Value Analysis")
    public static class BoundaryValueAnalysis {
        private final DateTimeValidationService validator = new DateTimeValidationService();

        // --- Minimum Boundaries ---

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=1, month=1, year=1000 -> VALID (absolute minimum)")
        public void testAbsoluteMinimumValid() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("1", "1", "1000"));
            org.junit.jupiter.api.Assertions.assertTrue(res.valid, "Expected valid absolute minimum date.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=0, month=1, year=1000 -> ERROR (Day out of range)")
        public void testDayZeroInvalid() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("0", "1", "1000"));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected invalid day 0.");
            org.junit.jupiter.api.Assertions.assertTrue(res.errors.get(0).contains("khoảng 1-31"), "Expected range error.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=1, month=0, year=1000 -> ERROR (Month out of range)")
        public void testMonthZeroInvalid() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("1", "0", "1000"));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected invalid month 0.");
            org.junit.jupiter.api.Assertions.assertTrue(res.errors.get(0).contains("khoảng 1-12"), "Expected range error.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=1, month=1, year=999 -> ERROR (Year out of range)")
        public void testYearBelowRangeInvalid() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("1", "1", "999"));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected invalid year 999.");
            org.junit.jupiter.api.Assertions.assertTrue(res.errors.get(0).contains("khoảng 1000-3000"), "Expected range error.");
        }

        // --- Maximum Boundaries ---

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=31, month=12, year=3000 -> VALID (absolute maximum)")
        public void testAbsoluteMaximumValid() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("31", "12", "3000"));
            org.junit.jupiter.api.Assertions.assertTrue(res.valid, "Expected valid absolute maximum date.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=32, month=12, year=3000 -> ERROR (Day out of range)")
        public void testDayAboveRangeInvalid() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("32", "12", "3000"));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected invalid day 32.");
            org.junit.jupiter.api.Assertions.assertTrue(res.errors.get(0).contains("khoảng 1-31"), "Expected range error.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=31, month=13, year=3000 -> ERROR (Month out of range)")
        public void testMonthAboveRangeInvalid() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("31", "13", "3000"));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected invalid month 13.");
            org.junit.jupiter.api.Assertions.assertTrue(res.errors.get(0).contains("khoảng 1-12"), "Expected range error.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=31, month=12, year=3001 -> ERROR (Year out of range)")
        public void testYearAboveRangeInvalid() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("31", "12", "3001"));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected invalid year 3001.");
            org.junit.jupiter.api.Assertions.assertTrue(res.errors.get(0).contains("khoảng 1000-3000"), "Expected range error.");
        }

        // --- Leap Year Edge Cases ---

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=29, month=2, year=2000 -> VALID (divisible by 400)")
        public void testLeapYearDivBy400() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("29", "2", "2000"));
            org.junit.jupiter.api.Assertions.assertTrue(res.valid, "Expected Feb 29, 2000 to be valid.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=29, month=2, year=1900 -> INVALID (divisible by 100, not 400)")
        public void testNonLeapYearDivBy100() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("29", "2", "1900"));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected Feb 29, 1900 to be invalid.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=29, month=2, year=2024 -> VALID (divisible by 4, not 100)")
        public void testLeapYearDivBy4() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("29", "2", "2024"));
            org.junit.jupiter.api.Assertions.assertTrue(res.valid, "Expected Feb 29, 2024 to be valid.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=29, month=2, year=2023 -> INVALID (not divisible by 4)")
        public void testNonLeapYearNotDivBy4() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("29", "2", "2023"));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected Feb 29, 2023 to be invalid.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=30, month=2, year=2024 -> INVALID (no Feb 30 ever)")
        public void testFeb30NeverValid() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("30", "2", "2024"));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected Feb 30 to be invalid.");
        }

        // --- Month-End Boundaries ---

        @org.junit.jupiter.params.ParameterizedTest(name = "day={0}, month={1}, year={2} -> expectedValid={3}")
        @org.junit.jupiter.params.provider.CsvSource({
            "30, 4, 2023, true",
            "31, 4, 2023, false",
            "30, 6, 2023, true",
            "31, 6, 2023, false",
            "30, 9, 2023, true",
            "31, 9, 2023, false",
            "30, 11, 2023, true",
            "31, 11, 2023, false"
        })
        @org.junit.jupiter.api.DisplayName("Month-end boundaries for 30-day months")
        public void testMonthEndBoundaries(String day, String month, String year, boolean expectedValid) {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest(day, month, year));
            org.junit.jupiter.api.Assertions.assertEquals(expectedValid, res.valid, 
                "Failed verification for " + day + "/" + month + "/" + year);
        }

        // --- Non-numeric inputs ---

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=abc -> ERROR (not a number)")
        public void testDayNotANumber() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("abc", "5", "2026"));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected non-numeric day to be invalid.");
            org.junit.jupiter.api.Assertions.assertTrue(res.errors.get(0).contains("số nguyên"), "Expected not a number error.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("month=5.5 -> ERROR (not a number)")
        public void testMonthDecimal() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("30", "5.5", "2026"));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected decimal month to be invalid.");
            org.junit.jupiter.api.Assertions.assertTrue(res.errors.get(0).contains("số nguyên"), "Expected not a number error.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("year='' -> ERROR (not a number)")
        public void testYearEmpty() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("30", "5", ""));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected empty year to be invalid.");
            org.junit.jupiter.api.Assertions.assertTrue(res.errors.get(0).contains("để trống"), "Expected blank error.");
        }

        @org.junit.jupiter.api.Test
        @org.junit.jupiter.api.DisplayName("day=-1 -> ERROR (out of range)")
        public void testDayNegativeOutOfRange() {
            DateTimeCheckResult res = validator.validate(new DateTimeCheckRequest("-1", "5", "2026"));
            org.junit.jupiter.api.Assertions.assertFalse(res.valid, "Expected negative day to be invalid.");
            org.junit.jupiter.api.Assertions.assertTrue(res.errors.get(0).contains("khoảng 1-31"), "Expected range error.");
        }
    }
}
