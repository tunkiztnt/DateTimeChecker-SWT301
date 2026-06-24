import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/date_time_validation_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/date_input_card.dart';
import '../widgets/result_card.dart';

class HomeScreen extends StatefulWidget {
  final HistoryService historyService;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.historyService,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _validator = DateTimeValidationService();
  final _dayCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  DateTimeCheckResult? _result;
  String _liveDate = '';
  Timer? _clockTimer;
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateClock(),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    if (!mounted) {
      return;
    }

    setState(() {
      _liveDate = DateFormat('EEEE, d MMMM yyyy', 'en_GB').format(now);
    });
  }

  void _fillToday() {
    final now = DateTime.now();
    _dayCtrl.text = now.day.toString();
    _monthCtrl.text = now.month.toString();
    _yearCtrl.text = now.year.toString();
  }

  void _onSubmit() {
    FocusScope.of(context).unfocus();
    final result = _validator.validate(
      DateTimeCheckRequest(
        day: _dayCtrl.text,
        month: _monthCtrl.text,
        year: _yearCtrl.text,
      ),
    );

    setState(() {
      _result = result;
    });
  }

  void _onClear() {
    _dayCtrl.clear();
    _monthCtrl.clear();
    _yearCtrl.clear();
    setState(() {
      _result = null;
    });
  }

  void _onUseToday() {
    _fillToday();
    _onSubmit();
  }

  Future<void> _onCloseTap() async {
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Exit'),
          content: const Text(
            'Are you sure you want to close the DateTimeChecker demo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (shouldClose == true && mounted) {
      setState(() {
        _isClosed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.bg,
              cs.bg.withValues(alpha: 0.96),
            ],
          ),
        ),
        child: SafeArea(
          child: _isClosed
              ? _ClosedView(
                  onReopen: () {
                    setState(() {
                      _isClosed = false;
                    });
                  },
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    children: [
                      _HeaderBar(
                        onToggleTheme: widget.onToggleTheme,
                        onClose: _onCloseTap,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Date Time Checker',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: cs.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _liveDate,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                      DateInputCard(
                        dayController: _dayCtrl,
                        monthController: _monthCtrl,
                        yearController: _yearCtrl,
                        onSubmit: _onSubmit,
                        onClear: _onClear,
                        onUseToday: _onUseToday,
                      ),
                      const SizedBox(height: 16),
                      ResultCard(result: _result),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onClose;

  const _HeaderBar({
    required this.onToggleTheme,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'FU',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FPT Education',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'FPT University',
                  style: TextStyle(
                    color: cs.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            identifier: 'theme_toggle_button',
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: cs.onSurface,
            onTap: onToggleTheme,
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.close_rounded,
            color: const Color(0xFFEF4444),
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String? identifier;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderIconButton({
    this.identifier,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );

    if (identifier == null) {
      return button;
    }

    return Semantics(
      identifier: identifier,
      button: true,
      child: button,
    );
  }
}

class _ClosedView extends StatelessWidget {
  final VoidCallback onReopen;

  const _ClosedView({required this.onReopen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.power_settings_new_rounded,
                size: 42,
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                'Application closed',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap Reopen to continue the mobile demo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onReopen,
                child: const Text('Reopen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
