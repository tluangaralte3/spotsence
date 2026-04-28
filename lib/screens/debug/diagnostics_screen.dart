import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../services/analytics_service.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Non-fatal error report
                final messenger = ScaffoldMessenger.of(context);
                final error = Exception(
                  'Test non-fatal error from Diagnostics',
                );
                await FirebaseCrashlytics.instance.recordError(
                  error,
                  StackTrace.current,
                  reason: 'diagnostics_non_fatal',
                );
                messenger.showSnackBar(
                  const SnackBar(content: Text('Non-fatal error recorded')),
                );
              },
              child: const Text('Record non-fatal error (safe)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirm crash'),
                    content: const Text(
                      'This will force the app to crash. Continue?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Crash'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  // This will crash the app (native). Only call when explicitly confirmed.
                  FirebaseCrashlytics.instance.crash();
                } else {
                  // ensure any navigation operations use the captured navigator
                  navigator.popUntil((r) => r.isFirst);
                }
              },
              child: const Text('Force native crash (confirm)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // Log a friendly screen name and an analytics event
                final messenger = ScaffoldMessenger.of(context);
                await AnalyticsService.instance.setCurrentScreen('Diagnostics');
                await AnalyticsService.instance.logTabChange(
                  tabName: 'diagnostics',
                  index: -1,
                );
                messenger.showSnackBar(
                  const SnackBar(content: Text('Analytics events sent')),
                );
              },
              child: const Text('Log analytics test events'),
            ),
            const SizedBox(height: 12),
            if (kDebugMode)
              Text(
                'Debug mode: Crash and analytics test buttons are visible only in debug builds.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
