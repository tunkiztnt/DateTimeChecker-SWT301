class DateTimeValidationService {
  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  DateTimeCheckResult validate(DateTimeCheckRequest request) {
    final dayError = _validateIntegerField(request.day, 'Day');
    if (dayError != null) {
      return DateTimeCheckResult(valid: false, errors: [dayError]);
    }

    final day = int.parse(request.day!.trim());
    if (day < 1 || day > 31) {
      return const DateTimeCheckResult(
        valid: false,
        errors: ['Day must be in range 1-31.'],
      );
    }

    final monthError = _validateIntegerField(request.month, 'Month');
    if (monthError != null) {
      return DateTimeCheckResult(valid: false, errors: [monthError]);
    }

    final month = int.parse(request.month!.trim());
    if (month < 1 || month > 12) {
      return const DateTimeCheckResult(
        valid: false,
        errors: ['Month must be in range 1-12.'],
      );
    }

    final yearError = _validateIntegerField(request.year, 'Year');
    if (yearError != null) {
      return DateTimeCheckResult(valid: false, errors: [yearError]);
    }

    final year = int.parse(request.year!.trim());
    if (year < 1000 || year > 3000) {
      return const DateTimeCheckResult(
        valid: false,
        errors: ['Year must be in range 1000-3000.'],
      );
    }

    final parts = DateTimeParts(day: day, month: month, year: year);
    final maximum = _daysInMonth(month, year);
    if (day > maximum) {
      return DateTimeCheckResult(
        valid: false,
        errors: ['Month $month of year $year has only $maximum days.'],
        parts: parts,
      );
    }

    final date = DateTime(year, month, day);
    final details = DateTimeDetails(
      display:
          '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year',
      weekday: _weekdays[date.weekday - 1],
      leapYear: _isLeapYear(year) ? 'Yes' : 'No',
      monthDays: _daysInMonth(month, year).toString(),
    );

    return DateTimeCheckResult(
      valid: true,
      errors: const [],
      parts: parts,
      details: details,
    );
  }

  static String? _validateIntegerField(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label cannot be empty.';
    }
    if (value.contains('.')) {
      return '$label must be an integer.';
    }
    if (int.tryParse(value.trim()) == null) {
      return '$label must be an integer.';
    }
    return null;
  }

  static bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  static int _daysInMonth(int month, int year) {
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && _isLeapYear(year)) {
      return 29;
    }
    return days[month];
  }
}

class DateTimeCheckRequest {
  final String? day;
  final String? month;
  final String? year;

  const DateTimeCheckRequest({this.day, this.month, this.year});
}

class DateTimeParts {
  final int day;
  final int month;
  final int year;

  const DateTimeParts({
    required this.day,
    required this.month,
    required this.year,
  });

  String get display =>
      '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';

  Map<String, dynamic> toJson() => {
        'day': day,
        'month': month,
        'year': year,
      };

  factory DateTimeParts.fromJson(Map<String, dynamic> json) => DateTimeParts(
        day: json['day'] as int,
        month: json['month'] as int,
        year: json['year'] as int,
      );
}

class DateTimeDetails {
  final String display;
  final String weekday;
  final String leapYear;
  final String monthDays;

  const DateTimeDetails({
    required this.display,
    required this.weekday,
    required this.leapYear,
    required this.monthDays,
  });
}

class DateTimeCheckResult {
  final bool valid;
  final List<String> errors;
  final DateTimeParts? parts;
  final DateTimeDetails? details;

  const DateTimeCheckResult({
    required this.valid,
    required this.errors,
    this.parts,
    this.details,
  });
}
