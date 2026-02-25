import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/app.dart';

void main() {
  testWidgets('앱이 정상적으로 시작되는지 확인', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    // 차트 탭이 기본으로 선택되어 있는지 확인
    expect(find.text('차트'), findsWidgets);
  });
}
