import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tugasakhir15/main.dart';
import 'package:tugasakhir15/providers/absen_provider.dart';
import 'package:tugasakhir15/providers/auth_provider.dart';
import 'package:tugasakhir15/providers/theme_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AbsenProvider()),
        ],
        child: const AbsensiApp(),
      ),
    );

    expect(find.byType(AbsensiApp), findsOneWidget);
  });
}

