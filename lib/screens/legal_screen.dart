import 'package:flutter/material.dart';

import '../config.dart';
import '../legal/legal_texts.dart';

String _withContact(String text) => text.replaceAll(
      '{contact}',
      AppConfig.supportEmail.isEmpty
          ? 'من خلال إدارة التطبيق.'
          : AppConfig.supportEmail,
    );

/// بيعرض سياسة الخصوصية أو شروط الاستخدام.
class LegalScreen extends StatelessWidget {
  const LegalScreen.privacy({super.key})
      : title = 'سياسة الخصوصية',
        text = privacyPolicyText;

  const LegalScreen.terms({super.key})
      : title = 'شروط الاستخدام',
        text = termsText;

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              _withContact(text),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
