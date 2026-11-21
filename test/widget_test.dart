import 'package:flutter_test/flutter_test.dart';
import 'package:qarib/data/demo_places_repository.dart';
import 'package:qarib/main.dart';
import 'package:qarib/services/auth_service.dart';

void main() {
  testWidgets('Home screen shows categories', (tester) async {
    await tester.pumpWidget(QaribApp(
      repository: DemoPlacesRepository(),
      auth: DemoAuthService(),
    ));
    await tester.pump();

    expect(find.text('قريب'), findsOneWidget);
    expect(find.text('صيدليات'), findsOneWidget);
    expect(find.text('أضف مكانك'), findsOneWidget);
  });
}
