import 'package:flutter/material.dart';
import '../../../core/theme.dart';

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
      dropdownColor: kPanel,
      iconEnabledColor: kTextMuted,
      style: const TextStyle(
        color: kTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: 'Language',
        prefixIcon: const Icon(Icons.language),
        filled: true,
        fillColor: kPanel,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0x1FFFFFFF),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: kBrandBlue,
            width: 1.5,
          ),
        ),
      ),
      items: _kLanguages.entries
          .map(
            (e) => DropdownMenuItem<String>(
              value: e.key,
              child: Text(
                '${e.key.toUpperCase()}  ${e.value}',
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
