import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/features/dashboard/telemetry_presentation.dart';

void main() {
  Widget pulse({required bool active, required bool reduceMotion}) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ChargingPulse(active: active, child: const Icon(Icons.bolt)),
      ),
    );
  }

  testWidgets('charges pulse only while active and motion is allowed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(pulse(active: true, reduceMotion: false));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await tester.pumpWidget(pulse(active: true, reduceMotion: true));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(pulse(active: false, reduceMotion: false));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
