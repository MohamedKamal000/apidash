import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/screens/terminal/terminal_page.dart';
import 'package:apidash/providers/terminal_providers.dart';
import 'package:apidash_core/apidash_core.dart';
import 'package:apidash/consts.dart';
import 'package:apidash/widgets/terminal_level_filter_menu.dart';
import 'package:apidash/models/request_model.dart';
import 'package:apidash/providers/collection_providers.dart';
import '../../providers/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget build(ProviderContainer container) {
    return ProviderScope(
      // ignore: deprecated_member_use
      parent: container,
      child: const MaterialApp(home: TerminalPage()),
    );
  }

  setUp(() async {
    await testSetUpTempDirForHive();
  });

  testWidgets('shows empty state initially', (tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(build(container));
    expect(find.text('No logs yet'), findsOneWidget);
  });

  testWidgets(
      'renders entries, filters by level and search, toggles timestamp, clears',
      (tester) async {
    final container = ProviderContainer();
    final term = container.read(terminalStateProvider.notifier);

    // Add entries: js (warn), system (info), network (error)
    term.logJs(
        level: 'warn',
        args: ['alpha'],
        context: 'preRequest',
        contextRequestId: 'r1');
    term.logSystem(category: 'ui', message: 'opened');
    final id = term.startNetwork(
        apiType: APIType.rest,
        method: HTTPVerb.get,
        url: 'https://api.apidash.dev',
        requestId: 'r2');
    term.completeNetwork(id, statusCode: 500, responseBodyPreview: 'boom');

    await tester.pumpWidget(build(container));

    // List has 3 entries
    expect(find.byType(ListView), findsOneWidget);
    // There are separators, but count entries by specific content
    // JS tile renders its body as SelectableText containing args/context
    final alphaText = find.byWidgetPredicate(
        (w) => w is SelectableText && (w.data?.contains('alpha') ?? false));
    expect(alphaText, findsOneWidget);
    expect(find.textContaining('[ui] opened'), findsOneWidget);
    final networkTitle = find.byWidgetPredicate((w) =>
        w is RichText &&
        w.text.toPlainText().contains('GET https://api.apidash.dev'));
    expect(networkTitle, findsOneWidget);

    // Search: find alpha
    final searchField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Search logs');
    await tester.enterText(searchField, 'alpha');
    await tester.pumpAndSettle();
    expect(alphaText, findsOneWidget);
    expect(find.textContaining('[ui] opened'), findsNothing);
    expect(networkTitle, findsNothing);

    // Clear search
    await tester.enterText(searchField, '');
    await tester.pumpAndSettle();

    // Deselect Errors level via filter menu callback to avoid popup flakiness
    final menuWidget = tester
        .widget<TerminalLevelFilterMenu>(find.byType(TerminalLevelFilterMenu));
    final newLevels = <TerminalLevel>{...menuWidget.selected}
      ..remove(TerminalLevel.error);
    menuWidget.onChanged(newLevels);
    await tester.pumpAndSettle();
    expect(networkTitle, findsNothing);

    // Toggle timestamp checkbox
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // We won't parse time, but ensure list still renders with entries
    expect(find.byType(ListView), findsOneWidget);

    // Clear logs button
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('No logs yet'), findsOneWidget);
  });

  testWidgets('displays [Untitled] when request name empty (JS + Network)',
      (tester) async {
    const reqId = 'req-empty-name';
    final container = ProviderContainer();

    // Seed collection with a RequestModel having empty name
    final collectionNotifier =
        container.read(collectionStateNotifierProvider.notifier);
    collectionNotifier.state = {reqId: RequestModel(id: reqId, name: '')};

    final term = container.read(terminalStateProvider.notifier);

    // JS log referencing the request id
    term.logJs(
      level: 'warn',
      args: const ['alpha'],
      context: 'preRequest',
      contextRequestId: reqId,
    );

    // Network log referencing the same request id
    final netId = term.startNetwork(
      apiType: APIType.rest,
      method: HTTPVerb.get,
      url: 'https://example.com',
      requestId: reqId,
    );
    term.completeNetwork(netId, statusCode: 200);

    await tester.pumpWidget(build(container));

    // JS tile body should contain [Untitled]
    final jsWithUntitled = find.byWidgetPredicate((w) =>
        w is SelectableText && (w.data?.contains('[Untitled]') ?? false));
    expect(jsWithUntitled, findsOneWidget);

    // Network title should start with [Untitled]
    final netWithUntitled = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().startsWith('[Untitled] '));
    expect(netWithUntitled, findsOneWidget);
  });
}
