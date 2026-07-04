import 'package:flutter/material.dart';

import '../constants/app_text_styles.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;

  const SectionTitle({super.key, required this.title, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(title, style: AppTextStyles.sectionTitle),
    );
  }
}
