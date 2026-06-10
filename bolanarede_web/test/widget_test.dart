import 'package:flutter_test/flutter_test.dart';

import 'package:bolanarede_web/app.dart';

void main() {
  testWidgets('App renders', (tester) async {
    await tester.pumpWidget(const BolaNaRedeWebApp());
  });
}
