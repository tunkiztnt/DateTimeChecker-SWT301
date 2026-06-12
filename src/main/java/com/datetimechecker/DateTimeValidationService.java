package com.datetimechecker;

import java.time.LocalDate;
import java.time.format.TextStyle;
import java.util.Locale;
import java.util.List;
import java.util.ArrayList;

public class DateTimeValidationService {

    public static final String RESULT_VALID = "VALID";
    public static final String RESULT_INVALID = "INVALID";
    public static final String RESULT_ERROR = "ERROR";

    public static class ValidationResult {
        public final String result;  // "VALID", "INVALID", or "ERROR"
        public final String message; // human-readable explanation

        public ValidationResult(String result, String message) {
            this.result = result;
            this.message = message;
        }
    }

    /**
     * Validate a date given string inputs (as received from HTTP params).
     * Returns a ValidationResult with result ("VALID"/"INVALID"/"ERROR")
     * and a human-readable message.
     */
    public ValidationResult validate(String dayStr, String monthStr, String yearStr) {
        // Step 1: Check null/blank
        if (dayStr == null || dayStr.trim().isEmpty()) {
            return new ValidationResult(RESULT_ERROR, "Ngày không được để trống.");
        }
        if (monthStr == null || monthStr.trim().isEmpty()) {
            return new ValidationResult(RESULT_ERROR, "Tháng không được để trống.");
        }
        if (yearStr == null || yearStr.trim().isEmpty()) {
            return new ValidationResult(RESULT_ERROR, "Năm không được để trống.");
        }

        // Step 2: Check each is a valid integer (no decimals, no letters)
        if (dayStr.contains(".") || monthStr.contains(".") || yearStr.contains(".")) {
            return new ValidationResult(RESULT_ERROR, "Ngày, tháng, năm phải là số nguyên.");
        }

        int day, month, year;
        try {
            day = Integer.parseInt(dayStr.trim());
        } catch (NumberFormatException e) {
            return new ValidationResult(RESULT_ERROR, "Ngày phải là số nguyên.");
        }
        try {
            month = Integer.parseInt(monthStr.trim());
        } catch (NumberFormatException e) {
            return new ValidationResult(RESULT_ERROR, "Tháng phải là số nguyên.");
        }
        try {
            year = Integer.parseInt(yearStr.trim());
        } catch (NumberFormatException e) {
            return new ValidationResult(RESULT_ERROR, "Năm phải là số nguyên.");
        }

        // Step 3: Check ranges: day 1-31, month 1-12, year 1000-3000
        if (day < 1 || day > 31) {
            return new ValidationResult(RESULT_ERROR, "Ngày phải nằm trong khoảng 1-31.");
        }
        if (month < 1 || month > 12) {
            return new ValidationResult(RESULT_ERROR, "Tháng phải nằm trong khoảng 1-12.");
        }
        if (year < 1000 || year > 3000) {
            return new ValidationResult(RESULT_ERROR, "Năm phải nằm trong khoảng 1000-3000.");
        }

        // Step 4: Use LocalDate.of(year, month, day) in a try-catch
        //         → success = VALID, DateTimeException = INVALID
        try {
            LocalDate.of(year, month, day);
            return new ValidationResult(RESULT_VALID, "Ngày hợp lệ.");
        } catch (java.time.DateTimeException e) {
            // Find the correct maxDays for the month to build the custom message
            boolean isLeap = ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0);
            int maxDays;
            switch (month) {
                case 2: maxDays = isLeap ? 29 : 28; break;
                case 4: case 6: case 9: case 11: maxDays = 30; break;
                default: maxDays = 31;
            }
            String msg = "Tháng " + month + " năm " + year + " chỉ có " + maxDays + " ngày.";
            return new ValidationResult(RESULT_INVALID, msg);
        }
    }

    // --- Backwards compatibility code for App.java and DateTimeValidationServiceTest.java ---

    public static final class DateTimeCheckRequest {
        public String day;
        public String month;
        public String year;

        public DateTimeCheckRequest() {}

        public DateTimeCheckRequest(String day, String month, String year) {
            this.day = day;
            this.month = month;
            this.year = year;
        }
    }

    public static final class DateTimeCheckDetails {
        public String display;
        public String weekday;
        public String leapYear;
        public String monthDays;
    }

    public static final class DateTimeCheckParts {
        public int day;
        public int month;
        public int year;
    }

    public static final class DateTimeCheckResult {
        public boolean valid;
        public String result;
        public String message;
        public List<String> errors = new ArrayList<>();
        public DateTimeCheckParts parts;
        public DateTimeCheckDetails details;

        public String toJson() {
            StringBuilder sb = new StringBuilder();
            sb.append("{");
            sb.append("\"valid\":").append(valid).append(",");
            sb.append("\"result\":\"").append(result != null ? result : (valid ? "VALID" : "ERROR")).append("\",");
            sb.append("\"message\":\"").append(message != null ? message.replace("\"", "\\\"") : "").append("\",");
            sb.append("\"errors\":[");
            for (int i = 0; i < errors.size(); i++) {
                sb.append("\"").append(errors.get(i).replace("\"", "\\\"")).append("\"");
                if (i < errors.size() - 1) sb.append(",");
            }
            sb.append("]");
            if (parts != null) {
                sb.append(",\"parts\":{");
                sb.append("\"day\":").append(parts.day).append(",");
                sb.append("\"month\":").append(parts.month).append(",");
                sb.append("\"year\":").append(parts.year);
                sb.append("}");
            } else {
                sb.append(",\"parts\":null");
            }
            if (details != null) {
                sb.append(",\"details\":{");
                sb.append("\"display\":\"").append(details.display).append("\",");
                sb.append("\"weekday\":\"").append(details.weekday).append("\",");
                sb.append("\"leapYear\":\"").append(details.leapYear).append("\",");
                sb.append("\"monthDays\":\"").append(details.monthDays).append("\"");
                sb.append("}");
            } else {
                sb.append(",\"details\":null");
            }
            sb.append("}");
            return sb.toString();
        }
    }

    public DateTimeCheckResult validate(DateTimeCheckRequest request) {
        DateTimeCheckResult result = new DateTimeCheckResult();
        if (request == null) {
            result.valid = false;
            result.result = RESULT_ERROR;
            result.message = "Yêu cầu rỗng.";
            result.errors.add("Yêu cầu rỗng.");
            return result;
        }

        ValidationResult valRes = validate(request.day, request.month, request.year);
        result.result = valRes.result;
        result.message = valRes.message;

        if (RESULT_VALID.equals(valRes.result)) {
            result.valid = true;

            int day = Integer.parseInt(request.day.trim());
            int month = Integer.parseInt(request.month.trim());
            int year = Integer.parseInt(request.year.trim());

            result.parts = new DateTimeCheckParts();
            result.parts.day = day;
            result.parts.month = month;
            result.parts.year = year;

            LocalDate date = LocalDate.of(year, month, day);
            boolean isLeap = date.isLeapYear();
            int maxDays = date.lengthOfMonth();

            String weekday = date.getDayOfWeek().getDisplayName(TextStyle.FULL, Locale.of("vi", "VN"));
            if (weekday != null) {
                weekday = weekday.toLowerCase();
                if (!weekday.isEmpty()) {
                    weekday = weekday.substring(0, 1).toUpperCase() + weekday.substring(1);
                }
            }

            result.details = new DateTimeCheckDetails();
            result.details.display = String.format("%02d/%02d/%04d", day, month, year);
            result.details.leapYear = isLeap ? "Có" : "Không";
            result.details.monthDays = String.valueOf(maxDays);
            result.details.weekday = weekday;
        } else {
            result.valid = false;
            result.errors.add(valRes.message);
        }

        return result;
    }
}
