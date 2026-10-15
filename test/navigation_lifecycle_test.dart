import 'package:child_tracker/config/router/data_route.dart';
import 'package:child_tracker/config/router/startup_redirect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('auth completion leaves splash and later navigation stays put', (tester) async {
    final checking = ValueNotifier(true);
    String? destination;
    final router = GoRouter(
      initialLocation: '/auth',
      refreshListenable: checking,
      redirect: (_, state) => startupRedirect(
        isCheckingAuth: checking.value,
        location: state.uri.path,
        initialRoute: destination,
      ),
      routes: [
        for (final path in ['/auth', '/splash', '/mentor_task', '/mentor_profile'])
          GoRoute(path: path, builder: (_, __) => Text(path)),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(checking.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('/splash'), findsOneWidget);

    destination = '/mentor_task';
    checking.value = false;
    await tester.pumpAndSettle();
    expect(find.text('/mentor_task'), findsOneWidget);

    router.go('/mentor_profile');
    await tester.pumpAndSettle();
    expect(find.text('/mentor_profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('completed check without a destination recovers to login', () {
    expect(startupRedirect(isCheckingAuth: false, location: '/splash', initialRoute: null), '/auth');
    expect(startupRedirect(isCheckingAuth: true, location: '/splash', initialRoute: null), isNull);
  });

  testWidgets('restored route without extras and malformed data recover safely', (tester) async {
    final router = GoRouter(
      initialLocation: '/details',
      routes: [
        DataRoute(
          path: '/details',
          builder: (_, state) {
            final data = state.extra as Map<String, dynamic>;
            return Text(data['name'] as String);
          },
          missingDataBuilder: () => const Text('Missing route data'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Missing route data'), findsOneWidget);

    router.go('/details', extra: <String, dynamic>{'name': 42});
    await tester.pumpAndSettle();
    expect(find.text('Missing route data'), findsOneWidget);

    router.go('/details', extra: <String, dynamic>{'name': 'Valid detail'});
    await tester.pumpAndSettle();
    expect(find.text('Valid detail'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
