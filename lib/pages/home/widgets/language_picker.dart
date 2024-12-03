import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/language.dart';

class LanguagePicker extends StatelessWidget {
  final Language selectedLanguage;
  final List<Language> availableLanguages;
  final Function(Language) onLanguageSelected;
  final String label;
  final bool isCompact;

  const LanguagePicker({
    super.key,
    required this.selectedLanguage,
    required this.availableLanguages,
    required this.onLanguageSelected,
    required this.label,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showLanguagePickerDialog(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8.w : 16.w,
          vertical: isCompact ? 8.h : 12.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(isCompact ? 8.r : 12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedLanguage.flag,
              style: TextStyle(fontSize: isCompact ? 18.sp : 24.sp),
            ),
            SizedBox(width: isCompact ? 4.w : 8.w),
            if (!isCompact) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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
            ] else ...[
              Text(
                selectedLanguage.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            SizedBox(width: isCompact ? 4.w : 8.w),
            Icon(
              Icons.arrow_drop_down,
              size: isCompact ? 20.w : 24.w,
            ),
          ],
        ),
      ),
    );
  }

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
              '选择$label',
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
}