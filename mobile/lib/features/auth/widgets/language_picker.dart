import 'package:flutter/material.dart';

/// Supported guest languages (ISO 639-1 code → display name).
const _kLanguages = {
  'en': 'English',
  'hi': 'हिन्दी',
  'ar': 'العربية',
  'es': 'Español',
  'fr': 'Français',
  'zh': '中文',
  'pt': 'Português',
  'ru': 'Русский',
  'de': 'Deutsch',
  'ja': '日本語',
};

/// Dropdown that lets the user choose their language during onboarding.
class LanguagePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const LanguagePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _kLanguages.containsKey(value) ? value : 'en',
      decoration: InputDecoration(
        labelText: 'Language',
        prefixIcon: const Icon(Icons.language),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _kLanguages.entries
          .map(
            (e) => DropdownMenuItem<String>(
              value: e.key,
              child: Text('${e.key.toUpperCase()}  ${e.value}'),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
