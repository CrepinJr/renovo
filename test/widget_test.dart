import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:renovo/core/theme/app_theme.dart';
import 'package:renovo/data/models/confession.dart';
import 'package:renovo/main.dart';
import 'package:renovo/providers/confessions_provider.dart';
import 'package:renovo/providers/selected_date_provider.dart';
import 'package:renovo/screens/home_screen.dart';

// Mock notifier for Confessions
class MockConfessionsNotifier extends ConfessionsNotifier {
  final List<Confession> initial;
  MockConfessionsNotifier([this.initial = const []]);

  @override
  Future<List<Confession>> build() async {
    return initial;
  }
}

// Mock notifier for SelectedDate
class MockSelectedDateNotifier extends SelectedDateNotifier {
  final DateTime initialDate;
  MockSelectedDateNotifier(this.initialDate);

  @override
  DateTime build() => initialDate;
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr_FR', null);
  });

  testWidgets('RenovoApp launches directly to HomeScreen without intermediate splash',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          confessionsProvider.overrideWith(() => MockConfessionsNotifier()),
        ],
        child: const RenovoApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title Renovo and immediate presence of HomeScreen
    expect(find.text('Renovo'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Nouvel enregistrement'), findsOneWidget);
  });

  testWidgets('Renovo HomeScreen renders correctly with title and circular floating button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          confessionsProvider.overrideWith(() => MockConfessionsNotifier()),
        ],
        child: MaterialApp(
          locale: const Locale('fr', 'FR'),
          supportedLocales: const [Locale('fr', 'FR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title Renovo
    expect(find.text('Renovo'), findsOneWidget);

    // Verify Legend items from Stitch design
    expect(find.text('Effectuée'), findsOneWidget);
    expect(find.text('Prévue (Samedi)'), findsOneWidget);

    // Verify Empty state message for default date
    expect(find.text('Aucune confession enregistrée'), findsOneWidget);

    // Verify Circular Floating Action Button with tooltip and add icon
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Nouvel enregistrement'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FloatingActionButton),
        matching: find.byIcon(Icons.add_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Displays effective confession details when selected date has a confession',
      (WidgetTester tester) async {
    final testDate = DateTime(2026, 11, 21);
    final mockConfession = Confession(
      id: 1,
      date: testDate,
      parish: 'Saint-Germain-des-Prés',
      notes: 'Pénitence: Chapelet',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          confessionsProvider.overrideWith(() => MockConfessionsNotifier([mockConfession])),
          selectedDateProvider.overrideWith(() => MockSelectedDateNotifier(testDate)),
        ],
        child: MaterialApp(
          locale: const Locale('fr', 'FR'),
          supportedLocales: const [Locale('fr', 'FR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Parish name and notes should be displayed
    expect(find.text('Saint-Germain-des-Prés'), findsOneWidget);
    expect(find.text('Pénitence: Chapelet'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
  });

  testWidgets('Displays prediction notice when selected date is a calculated Saturday',
      (WidgetTester tester) async {
    // Effective confession was Nov 21, 2026 (Saturday)
    final effectiveDate = DateTime(2026, 11, 21);
    // Next prediction is Dec 12, 2026 (+21 days, Saturday)
    final predictedSaturday = DateTime(2026, 12, 12);

    final mockConfession = Confession(
      id: 1,
      date: effectiveDate,
      parish: 'Notre-Dame des Victoires',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          confessionsProvider.overrideWith(() => MockConfessionsNotifier([mockConfession])),
          selectedDateProvider.overrideWith(() => MockSelectedDateNotifier(predictedSaturday)),
        ],
        child: MaterialApp(
          locale: const Locale('fr', 'FR'),
          supportedLocales: const [Locale('fr', 'FR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify prediction badge and quick button
    expect(find.text('Prochaine confession prévue'), findsOneWidget);
    expect(find.text('Marquer comme effectuée'), findsOneWidget);
  });
}
