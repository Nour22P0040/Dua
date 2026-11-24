import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';

enum _Unit { minutes, hours }

/// Asks for a number + unit. Returns the interval in minutes, or null.
Future<int?> showCustomIntervalDialog(BuildContext context, {required int initialMinutes}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _CustomIntervalDialog(initialMinutes: initialMinutes),
  );
}

class _CustomIntervalDialog extends StatefulWidget {
  const _CustomIntervalDialog({required this.initialMinutes});
  final int initialMinutes;

  @override
  State<_CustomIntervalDialog> createState() => _CustomIntervalDialogState();
}

class _CustomIntervalDialogState extends State<_CustomIntervalDialog> {
  final _formKey = GlobalKey<FormState>();
  late _Unit _unit;
  late final TextEditingController _value;

  // Limits: 1 minute (handy for testing) up to 7 days.
  static const _maxMinutes = 24 * 60;
  static const _maxHours = 7 * 24;

  @override
  void initState() {
    super.initState();
    final m = widget.initialMinutes;
    _unit = (m >= 60 && m % 60 == 0) ? _Unit.hours : _Unit.minutes;
    _value = TextEditingController(text: '${_unit == _Unit.hours ? m ~/ 60 : m}');
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  int get _max => _unit == _Unit.hours ? _maxHours : _maxMinutes;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final n = int.parse(_value.text.trim());
    Navigator.of(context).pop(_unit == _Unit.hours ? n * 60 : n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.customInterval),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _value,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l10n.enterNumber),
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 1 || n > _max) return l10n.invalidNumber(1, _max);
                return null;
              },
            ),
            const SizedBox(height: 16),
            SegmentedButton<_Unit>(
              segments: [
                ButtonSegment(value: _Unit.minutes, label: Text(l10n.minutes)),
                ButtonSegment(value: _Unit.hours, label: Text(l10n.hours)),
              ],
              selected: {_unit},
              onSelectionChanged: (s) {
                setState(() => _unit = s.first);
                _formKey.currentState?.validate();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
