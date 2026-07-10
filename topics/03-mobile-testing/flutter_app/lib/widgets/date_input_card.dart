import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class DateInputCard extends StatelessWidget {
  final TextEditingController dayController;
  final TextEditingController monthController;
  final TextEditingController yearController;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onUseToday;

  const DateInputCard({
    super.key,
    required this.dayController,
    required this.monthController,
    required this.yearController,
    required this.onSubmit,
    required this.onClear,
    required this.onUseToday,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateField(
            controller: dayController,
            identifier: 'day_input',
            label: 'Day',
            hint: 'e.g. 30',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _DateField(
            controller: monthController,
            identifier: 'month_input',
            label: 'Month',
            hint: 'e.g. 5',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _DateField(
            controller: yearController,
            identifier: 'year_input',
            label: 'Year',
            hint: 'e.g. 2026',
            textInputAction: TextInputAction.done,
            onSubmitted: onSubmit,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  identifier: 'clear_data_button',
                  button: true,
                  child: OutlinedButton(
                    onPressed: onClear,
                    child: const Text('Clear'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  identifier: 'use_today_button',
                  button: true,
                  child: OutlinedButton(
                    onPressed: onUseToday,
                    child: const Text('Use Today'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  identifier: 'check_now_button',
                  button: true,
                  child: FilledButton(
                    onPressed: onSubmit,
                    child: const Text('Check'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String identifier;
  final String label;
  final String hint;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  const _DateField({
    required this.controller,
    required this.identifier,
    required this.label,
    required this.hint,
    required this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          identifier: identifier,
          textField: true,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            textInputAction: textInputAction,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.-]')),
            ],
            decoration: InputDecoration(hintText: hint),
            onFieldSubmitted: (_) => onSubmitted?.call(),
          ),
        ),
      ],
    );
  }
}
