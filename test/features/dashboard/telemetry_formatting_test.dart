import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/features/dashboard/telemetry_presentation.dart';

void main() {
  test('groups thousands', () {
    expect(groupThousands(0), '0');
    expect(groupThousands(999), '999');
    expect(groupThousands(1000), '1,000');
    expect(groupThousands(1234567), '1,234,567');
    expect(groupThousands(-4500), '-4,500');
  });

  test('formats milliamps with an explicit direction when signed', () {
    expect(formatMilliampsValue(1499.6, signed: true), '+1,500');
    expect(formatMilliampsValue(-482.5, signed: true), '−483');
    expect(formatMilliampsValue(0.2, signed: true), '0');
    expect(formatMilliampsValue(-75), '−75');
    expect(formatMilliampsValue(2100), '2,100');
  });
}
