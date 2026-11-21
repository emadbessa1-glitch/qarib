import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/reports_repository.dart';
import '../services/auth_service.dart';

/// نافذة الإبلاغ: المستخدم بيختار السبب والبلاغ بيروح للإدارة.
Future<void> showReportDialog(
  BuildContext context, {
  required ReportTarget target,
  String placeId = '',
  String chatId = '',
  String itemId = '',
  String reportedUserId = '',
  String excerpt = '',
}) async {
  final repo = context.read<ReportsRepository>();
  final auth = context.read<AuthService>();
  final messenger = ScaffoldMessenger.of(context);

  final reason = await showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(target: target),
  );
  if (reason == null) return;

  try {
    await auth.ensureSignedIn();
    await repo.submit(Report(
      id: '',
      target: target,
      reason: reason,
      reporterId: auth.userId ?? '',
      createdAt: DateTime.now(),
      placeId: placeId,
      chatId: chatId,
      itemId: itemId,
      reportedUserId: reportedUserId,
      excerpt: excerpt,
    ));
    messenger.showSnackBar(const SnackBar(
      content: Text('شكراً، البلاغ وصل للإدارة وهيتراجع'),
    ));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('البلاغ ماتبعتش، حاول تاني')),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.target});

  final ReportTarget target;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إبلاغ عن ${widget.target.label}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in reportReasons)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  _reason == r
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(r),
                onTap: () => setState(() => _reason = r),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed:
              _reason == null ? null : () => Navigator.of(context).pop(_reason),
          child: const Text('إبلاغ'),
        ),
      ],
    );
  }
}
