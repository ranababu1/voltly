import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/errors/telemetry_exception.dart';
import 'package:voltly/core/telemetry/battery_telemetry_service.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

import '../../support/telemetry_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel methodChannel = MethodChannel(
    PlatformBatteryTelemetryService.methodChannelName,
  );
  const EventChannel eventChannel = EventChannel(
    PlatformBatteryTelemetryService.eventChannelName,
  );
  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockStreamHandler(eventChannel, null);
  });

  test('readSnapshot invokes getSnapshot and parses the payload', () async {
    MethodCall? captured;
    messenger.setMockMethodCallHandler(methodChannel, (MethodCall call) async {
      captured = call;
      return telemetryPayload();
    });

    final TelemetrySnapshot snapshot = await PlatformBatteryTelemetryService()
        .readSnapshot();

    expect(captured?.method, PlatformBatteryTelemetryService.getSnapshotMethod);
    expect(snapshot.batteryLevel.value, 72);
    expect(snapshot.batteryLevel.isAvailable, isTrue);
  });

  test('readSnapshot rejects an unsupported payload', () async {
    messenger.setMockMethodCallHandler(
      methodChannel,
      (MethodCall call) async => telemetryPayload(schemaVersion: 99),
    );

    await expectLater(
      PlatformBatteryTelemetryService().readSnapshot(),
      throwsA(isA<TelemetryFormatException>()),
    );
  });

  test('readSnapshot rejects a missing payload', () async {
    messenger.setMockMethodCallHandler(
      methodChannel,
      (MethodCall call) async => null,
    );

    await expectLater(
      PlatformBatteryTelemetryService().readSnapshot(),
      throwsA(isA<TelemetryFormatException>()),
    );
  });

  test(
    'watch parses streamed snapshots and cancels its subscription',
    () async {
      final Completer<void> cancelled = Completer<void>();
      messenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (Object? arguments, MockStreamHandlerEventSink events) {
            events.success(telemetryPayload());
          },
          onCancel: (Object? arguments) {
            cancelled.complete();
          },
        ),
      );

      final TelemetrySnapshot snapshot = await PlatformBatteryTelemetryService()
          .watch()
          .first;

      await cancelled.future.timeout(const Duration(seconds: 1));
      expect(snapshot.plugSource.value, BatteryPlugSource.usb);
    },
  );

  test('watch propagates native platform errors', () async {
    messenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (Object? arguments, MockStreamHandlerEventSink events) {
          events.error(
            code: 'telemetry_receiver_failed',
            message: 'Receiver denied',
          );
        },
      ),
    );

    await expectLater(
      PlatformBatteryTelemetryService().watch(),
      emitsError(isA<PlatformException>()),
    );
  });

  test('watch surfaces an invalid payload as a format error', () async {
    messenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (Object? arguments, MockStreamHandlerEventSink events) {
          events.success(telemetryPayload(schemaVersion: 99));
        },
      ),
    );

    await expectLater(
      PlatformBatteryTelemetryService().watch(),
      emitsError(isA<TelemetryFormatException>()),
    );
  });
}
