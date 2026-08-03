import 'package:flutter/material.dart';

/// Generic "type a value, hit enter/add, see it as a removable chip" input.
/// Used by meeting create/edit (tags, participant emails) and could replace
/// the inline skills-chip logic in the profile screen too.
class ChipInputField extends StatefulWidget {
  const ChipInputField({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final TextInputType? keyboardType;

  /// Return an error message to reject the value (e.g. invalid email), or
  /// null to accept it.
  final String? Function(String value)? validator;

  @override
  State<ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<ChipInputField> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;

    final error = widget.validator?.call(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    if (widget.values.contains(value)) {
      _controller.clear();
      return;
    }

    widget.onChanged([...widget.values, value]);
    _controller.clear();
    setState(() => _error = null);
  }

  void _remove(String value) {
    widget.onChanged(widget.values.where((v) => v != value).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.values.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in widget.values)
                  Chip(label: Text(value), onDeleted: () => _remove(value)),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: widget.keyboardType,
                decoration: InputDecoration(labelText: widget.label, errorText: _error),
                onSubmitted: (_) => _add(),
              ),
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: _add),
          ],
        ),
      ],
    );
  }
}
