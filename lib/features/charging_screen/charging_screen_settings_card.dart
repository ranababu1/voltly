import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/app/theme/app_tokens.dart';
import 'package:voltly/core/charging_screen/charging_screen_providers.dart';
import 'package:voltly/core/charging_screen/charging_screen_service.dart';
import 'package:voltly/features/charging_screen/charging_screen.dart';

/// Dashboard card for the opt-in lock-screen charging screen.
///
/// Explains in context why Voltly needs a persistent notification and
/// notification permission before requesting either.
class ChargingScreenSettingsCard extends ConsumerWidget {
  const ChargingScreenSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChargingScreenStatus? status = ref
        .watch(chargingScreenStatusProvider)
        .value;
    if (status == null || !status.supported) return const SizedBox.shrink();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('Charging screen', style: textTheme.titleMedium),
                ),
                Switch(
                  value: status.enabled,
                  onChanged: (bool value) =>
                      unawaited(_toggle(context, ref, value)),
                ),
              ],
            ),
            Text(
              'Shows the time, battery level, temperature, current and '
              'estimate on the lock screen when you plug in. Keeps a silent '
              'notification while on.',
              style: textTheme.bodyMedium,
            ),
            if (status.enabled && !status.notificationsAllowed) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              _Warning(
                text:
                    'Notifications are off for Voltly, so the screen cannot '
                    'open. Allow notifications in system settings.',
              ),
            ] else if (status.enabled && !status.fullScreenAllowed) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              _Warning(
                text:
                    'Android is blocking full-screen launches, so you will '
                    'only get a notification.',
                actionLabel: 'Allow',
                onAction: () => unawaited(
                  ref
                      .read(chargingScreenServiceProvider)
                      .openFullScreenSettings(),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const ChargingScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Preview'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final ChargingScreenEnableIssue? issue = await ref
        .read(chargingScreenStatusProvider.notifier)
        .setEnabled(value);
    if (issue == ChargingScreenEnableIssue.notificationsDenied) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'The charging screen needs notification permission to open on '
            'the lock screen.',
          ),
        ),
      );
    }
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.warning),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
