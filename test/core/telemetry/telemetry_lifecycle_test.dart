import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';

import '../../support/fake_battery_telemetry_service.dart';
import '../../support/telemetry_fixtures.dart';

void main() {
  test(
    'pauses acquisition while inactive and keeps the last snapshot',
    () async {
      final FakeBatteryTelemetryService fake = FakeBatteryTelemetryService();
      final ProviderContainer container = ProviderContainer(
        overrides: [batteryTelemetryServiceProvider.overrideWithValue(fake)],
      );
      final subscription = container.listen(
        telemetrySnapshotProvider,
        (_, _) {},
      );
      addTearDown(() async {
        subscription.close();
        container.dispose();
        await fake.dispose();
      });

      await pumpEventQueue();
      expect(fake.activeSubscriptions, 1);

      final TelemetrySnapshot first = snapshotAt(DateTime.now());
      fake.emit(first);
      await pumpEventQueue();
      expect(
        container.read(telemetrySnapshotProvider.notifier).lastSnapshot,
        same(first),
      );
      expect(container.read(telemetrySnapshotProvider).value, same(first));

      container.read(appActiveProvider.notifier).setActive(false);
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(appActiveProvider), isFalse);
      expect(
        container.read(telemetrySnapshotProvider.notifier).isSubscribed,
        isFalse,
      );
      expect(fake.activeSubscriptions, 0);
      expect(container.read(telemetrySnapshotProvider).value, same(first));

      final TelemetrySnapshot second = snapshotAt(
        DateTime.now().add(const Duration(seconds: 1)),
      );
      fake.emit(second);
      await pumpEventQueue();
      expect(container.read(telemetrySnapshotProvider).value, same(first));

      container.read(appActiveProvider.notifier).setActive(true);
      await pumpEventQueue();
      expect(fake.activeSubscriptions, 1);
      expect(
        container.read(telemetrySnapshotProvider.notifier).lastSnapshot,
        same(second),
      );
      expect(container.read(telemetrySnapshotProvider).value, same(second));
    },
  );

  test('does not acquire telemetry when starting inactive', () async {
    final FakeBatteryTelemetryService fake = FakeBatteryTelemetryService();
    final ProviderContainer container = ProviderContainer(
      overrides: [batteryTelemetryServiceProvider.overrideWithValue(fake)],
    );
    container.read(appActiveProvider.notifier).setActive(false);
    final subscription = container.listen(telemetrySnapshotProvider, (_, _) {});
    addTearDown(() async {
      subscription.close();
      container.dispose();
      await fake.dispose();
    });

    await pumpEventQueue();
    expect(fake.activeSubscriptions, 0);
    expect(container.read(telemetrySnapshotProvider).hasValue, isFalse);

    container.read(appActiveProvider.notifier).setActive(true);
    await pumpEventQueue();
    expect(fake.activeSubscriptions, 1);
  });
}
