import 'package:flutter/material.dart';
import '../../../data/models/language.dart';

class LanguagePicker extends StatelessWidget {
  final Language selectedLanguage;
  final List<Language> availableLanguages;
  final Function(Language) onLanguageSelected;
  final String label;

  const LanguagePicker({
    super.key,
    required this.selectedLanguage,
    required this.availableLanguages,
    required this.onLanguageSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showLanguagePickerDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedLanguage.flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  selectedLanguage.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _showLanguagePickerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '选择$label',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ...availableLanguages.map((language) => ListTile(
              leading: Text(
                language.flag,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(language.name),
              onTap: () {
                onLanguageSelected(language);
                Navigator.pop(context);
              },
              selected: language == selectedLanguage,
            )).toList(),
          ],
        ),
      ),
    );
  }
}