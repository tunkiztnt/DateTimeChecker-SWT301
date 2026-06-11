package com.datetimechecker;

import java.time.LocalDate;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public final class DateTimeValidationService {

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
        public List<String> errors = new ArrayList<>();
        public DateTimeCheckParts parts;
        public DateTimeCheckDetails details;

        public String toJson() {
            StringBuilder sb = new StringBuilder();
            sb.append("{");
            sb.append("\"valid\":").append(valid).append(",");
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
            result.errors.add("Yêu cầu rỗng.");
            return result;
        }

        String dStr = request.day == null ? "" : request.day.trim();
        String mStr = request.month == null ? "" : request.month.trim();
        String yStr = request.year == null ? "" : request.year.trim();

        if (dStr.isEmpty()) result.errors.add("Ngày không được để trống.");
        if (mStr.isEmpty()) result.errors.add("Tháng không được để trống.");
        if (yStr.isEmpty()) result.errors.add("Năm không được để trống.");

        if (!result.errors.isEmpty()) {
            result.valid = false;
            return result;
        }

        int day = 0, month = 0, year = 0;
        boolean hasFormatError = false;

        try {
            day = Integer.parseInt(dStr);
        } catch (NumberFormatException e) {
            result.errors.add("Ngày phải là số nguyên.");
            hasFormatError = true;
        }
        try {
            month = Integer.parseInt(mStr);
        } catch (NumberFormatException e) {
            result.errors.add("Tháng phải là số nguyên.");
            hasFormatError = true;
        }
        try {
            year = Integer.parseInt(yStr);
        } catch (NumberFormatException e) {
            result.errors.add("Năm phải là số nguyên.");
            hasFormatError = true;
        }

        if (hasFormatError) {
            result.valid = false;
            return result;
        }

        boolean hasRangeError = false;
        if (day < 1 || day > 31) {
            result.errors.add("Ngày phải nằm trong khoảng 1-31.");
            hasRangeError = true;
        }
        if (month < 1 || month > 12) {
            result.errors.add("Tháng phải nằm trong khoảng 1-12.");
            hasRangeError = true;
        }
        if (year < 1000 || year > 3000) {
            result.errors.add("Năm phải nằm trong khoảng 1000-3000.");
            hasRangeError = true;
        }

        if (hasRangeError) {
            result.valid = false;
            return result;
        }

        // Check leap year and month days
        boolean isLeap = isLeapYear(year);
        int maxDays = getDaysInMonth(month, isLeap);

        if (day > maxDays) {
            result.errors.add("Tháng " + month + " năm " + year + " chỉ có " + maxDays + " ngày.");
            result.valid = false;
            return result;
        }

        result.valid = true;
        
        result.parts = new DateTimeCheckParts();
        result.parts.day = day;
        result.parts.month = month;
        result.parts.year = year;

        result.details = new DateTimeCheckDetails();
        result.details.display = String.format("%02d/%02d/%04d", day, month, year);
        result.details.leapYear = isLeap ? "Có" : "Không";
        result.details.monthDays = String.valueOf(maxDays);

        try {
            LocalDate date = LocalDate.of(year, month, day);
            String weekday = date.getDayOfWeek().getDisplayName(TextStyle.FULL, new Locale("vi", "VN"));
            // Capitalize first letter
            if (weekday != null) {
                weekday = weekday.toLowerCase();
                if (!weekday.isEmpty()) {
                    weekday = weekday.substring(0, 1).toUpperCase() + weekday.substring(1);
                }
            }
            result.details.weekday = weekday;
        } catch (Exception e) {
            result.details.weekday = "Không xác định";
        }

        return result;
    }

    private boolean isLeapYear(int year) {
        if (year % 400 == 0) return true;
        if (year % 100 == 0) return false;
        return year % 4 == 0;
    }

    private int getDaysInMonth(int month, boolean isLeap) {
        switch (month) {
            case 2: return isLeap ? 29 : 28;
            case 4:
            case 6:
            case 9:
            case 11: return 30;
            default: return 31;
        }
    }
}
