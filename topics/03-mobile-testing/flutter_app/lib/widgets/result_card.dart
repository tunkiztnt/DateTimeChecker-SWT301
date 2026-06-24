import 'package:flutter/material.dart';

import '../services/date_time_validation_service.dart';
import '../theme/app_theme.dart';

class ResultCard extends StatelessWidget {
  final DateTimeCheckResult? result;

  const ResultCard({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: cs.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: cs.brightness == Brightness.dark ? 0.18 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: result == null ? const _EmptyState() : _ResultState(result: result!),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: cs.surfaceSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: cs.muted,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for validation',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Enter day, month, year and tap Check to validate the date.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.muted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultState extends StatelessWidget {
  final DateTimeCheckResult result;

  const _ResultState({required this.result});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isValid = result.valid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid ? cs.successBg : cs.errorBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isValid ? cs.successBorder : cs.errorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isValid ? cs.successText : cs.errorText,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isValid ? Icons.check_rounded : Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isValid ? 'Valid date' : 'Invalid date',
                style: TextStyle(
                  color: isValid ? cs.successText : cs.errorText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isValid && result.details != null) ...[
            Text(
              '${result.details!.display} is a valid date.',
              style: TextStyle(
                color: cs.successText,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _DetailGrid(details: result.details!),
          ] else ...[
            _ErrorList(errors: result.errors),
          ],
        ],
      ),
    );
  }
}

class _ErrorList extends StatelessWidget {
  final List<String> errors;

  const _ErrorList({required this.errors});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: errors.map((error) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  color: cs.errorText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(
                    color: cs.errorText,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final DateTimeDetails details;

  const _DetailGrid({required this.details});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      ('Weekday', details.weekday),
      ('Leap Year', details.leapYear),
      ('Days in Month', details.monthDays),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.line),
      ),
      child: Column(
        children: items.map((item) {
          final isLast = item == items.last;
          return Container(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10, top: 4),
            margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: cs.line)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.$1,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  item.$2,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
