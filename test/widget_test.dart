import 'package:flutter_test/flutter_test.dart';
import 'package:pos_umkm_offline/main.dart';

void main() {
  testWidgets('Aplikasi POS berhasil dijalankan', (WidgetTester tester) async {
    await tester.pumpWidget(const AplikasiPos());

    expect(find.byType(AplikasiPos), findsOneWidget);
  });
}
