import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/language.dart';

class SourceLanguageSelector extends StatelessWidget {
  final Language selectedLanguage;
  final List<Language> availableLanguages;
  final Function(Language) onLanguageSelected;

  const SourceLanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.availableLanguages,
    required this.onLanguageSelected,
  });

  void _showLanguagePickerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '选择源语言',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            20.verticalSpace,
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableLanguages.map((language) => ListTile(
                    leading: Text(
                      language.flag,
                      style: TextStyle(fontSize: 24.sp),
                    ),
                    title: Text(language.name),
                    onTap: () {
                      onLanguageSelected(language);
                      Navigator.pop(context);
                    },
                    selected: language == selectedLanguage,
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.person,
          size: 24.w,
          color: Colors.grey,
        ),
        12.horizontalSpace,
        TextButton(
          onPressed: () => _showLanguagePickerDialog(context),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedLanguage.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ],
    );
  }
}
