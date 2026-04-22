import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quranicpomodoro/main.dart';
import 'package:quranicpomodoro/services/pomodoro_service.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PomodoroService(),
        child: const QuranicPomodoroApp(),
      ),
    );

    // Verify the app title is shown
    expect(find.text('Quranic Pomodoro'), findsOneWidget);
  });
}
