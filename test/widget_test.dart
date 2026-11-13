import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_lobao/features/auth/data/repositories/auth_repository.dart';
import 'package:time_lobao/features/auth/presentation/providers/auth_provider.dart';
import 'package:time_lobao/main.dart';
import 'package:time_lobao/shared/widgets/brand_wordmark.dart';

/// Repositório falso: ninguém logado, sem tocar no Firebase.
class _LoggedOutAuthRepository implements AuthRepository {
  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Splash mostra a marca e, sem sessão, leva ao login',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_LoggedOutAuthRepository()),
        ],
        child: const TimeLobaoApp(),
      ),
    );

    expect(find.byType(BrandWordmark), findsOneWidget);
    expect(find.text('Mesma essência. Mais força. Mais resultados.'),
        findsOneWidget);

    await tester.pumpAndSettle();

    // Sem usuário logado o go_router redireciona para o login.
    expect(find.text('Mesma essência. Mais força. Mais resultados.'),
        findsNothing);
  });
}
