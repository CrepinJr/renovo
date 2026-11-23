import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:renovo/core/theme/app_theme.dart';
import 'package:renovo/data/models/confession.dart';
import 'package:renovo/main.dart';
import 'package:renovo/core/utils/date_utils.dart';
import 'package:renovo/providers/confessions_provider.dart';
import 'package:renovo/providers/selected_date_provider.dart';
import 'package:renovo/screens/account_cloud_backup_screen.dart';
import 'package:renovo/screens/home_screen.dart';
import 'package:renovo/services/auth_service.dart';
import 'package:renovo/widgets/annual_share_card.dart';
import 'package:renovo/widgets/annual_report_section.dart';
import 'package:renovo/widgets/customize_share_card_modal.dart';
import 'package:renovo/widgets/sign_out_confirmation_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets(
    'RenovoApp launches directly to HomeScreen without intermediate splash',
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
    },
  );

  testWidgets(
    'Renovo HomeScreen renders correctly with title and circular floating button',
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
    },
  );

  testWidgets('Guest backup pill opens the local account screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          confessionsProvider.overrideWith(() => MockConfessionsNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Local'), findsOneWidget);
    await tester.tap(find.text('Local'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountCloudBackupScreen), findsOneWidget);
    expect(find.text('Stockage local'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
  });

  testWidgets('Annual report filters by year and bounds year navigation', (
    WidgetTester tester,
  ) async {
    final currentYear = DateTime.now().year;
    final confessions = [
      Confession(date: DateTime(currentYear, 3, 14), parish: 'Saint Joseph'),
      Confession(date: DateTime(currentYear - 1, 12, 31), parish: 'Notre-Dame'),
      Confession(date: DateTime(currentYear + 1, 1, 1), parish: 'Saint Paul'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          confessionsProvider.overrideWith(
            () => MockConfessionsNotifier(confessions),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(child: AnnualReportSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 confession effectuée en $currentYear'), findsOneWidget);
    final nextYearButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('annual-year-next')),
    );
    expect(nextYearButton.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('annual-year-previous')));
    await tester.pumpAndSettle();
    expect(
      find.text('1 confession effectuée en ${currentYear - 1}'),
      findsOneWidget,
    );
    final previousYearButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('annual-year-previous')),
    );
    expect(previousYearButton.onPressed, isNull);
  });

  testWidgets(
    'Annual export buttons have matching size and single-line labels',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            confessionsProvider.overrideWith(() => MockConfessionsNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SingleChildScrollView(child: AnnualReportSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Exporter en image'),
      );
      final csvButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Exporter en CSV'),
      );
      expect(
        imageButton.style?.minimumSize?.resolve({})?.height,
        csvButton.style?.minimumSize?.resolve({})?.height,
      );
      expect(imageButton.style?.minimumSize?.resolve({})?.height, 44);
      for (final button in [imageButton, csvButton]) {
        final label = tester.widget<Text>(
          find.descendant(
            of: find.byWidget(button),
            matching: find.text(
              button == imageButton ? 'Exporter en image' : 'Exporter en CSV',
            ),
          ),
        );
        expect(label.maxLines, 1);
        expect(label.softWrap, isFalse);
      }
    },
  );

  testWidgets(
    'Share-card customization loads saved pseudo and hides guest email option',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'renovo_share_pseudo': 'Pèlerin de paix',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        const CustomizeShareCardModal(selectedYear: 2026),
                  ),
                  child: const Text('Personnaliser'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Personnaliser'));
      await tester.pumpAndSettle();

      expect(find.text('Bilan annuel 2026'), findsOneWidget);
      expect(find.text('Afficher mon adresse e-mail'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'Pèlerin de paix',
      );

      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Annual share card keeps its 4:5 portrait proportions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          body: Center(
            child: AnnualShareCard(
              pseudo: 'Pèlerin',
              showEmail: false,
              selectedYear: 2026,
              confessions: [],
              user: null,
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(AnnualShareCard));
    expect(size.width, 400);
    expect(size.height, 500);
    expect(find.text('BILAN ANNUEL 2026'), findsOneWidget);
    expect(find.text('Renouveau & Paix intérieure'), findsOneWidget);
  });

  testWidgets(
    'Annual CSV includes a BOM and correctly escaped French columns',
    (WidgetTester tester) async {
      final csv = buildAnnualConfessionsCsv([
        Confession(
          date: DateTime(2026, 1, 1),
          parish: 'Paroisse; "Saint"',
          notes: 'Notes; privées',
        ),
      ]);

      expect(csv, startsWith('\uFEFFDate;Jour;Paroisse;Statut;Notes\r\n'));
      expect(
        csv,
        contains(
          '"01/01/2026";"jeudi";"Paroisse; ""Saint""";"Effectuée";"Notes; privées"',
        ),
      );
    },
  );

  testWidgets('Sign-out modal offers both data choices and can be cancelled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      const SignOutConfirmationModal(uid: 'test-user'),
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('Conserver une copie sur l’appareil'), findsOneWidget);
    expect(find.text('Vider le calendrier local'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Se déconnecter du compte ?'), findsNothing);
  });

  testWidgets(
    'Displays effective confession details when selected date has a confession',
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
            confessionsProvider.overrideWith(
              () => MockConfessionsNotifier([mockConfession]),
            ),
            selectedDateProvider.overrideWith(
              () => MockSelectedDateNotifier(testDate),
            ),
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
    },
  );

  testWidgets(
    'Displays prediction notice when selected date is a calculated Saturday',
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
            confessionsProvider.overrideWith(
              () => MockConfessionsNotifier([mockConfession]),
            ),
            selectedDateProvider.overrideWith(
              () => MockSelectedDateNotifier(predictedSaturday),
            ),
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

      // The future prediction remains visible without an action to record it.
      expect(find.text('Prochaine confession prévue'), findsOneWidget);
      expect(find.text('Marquer comme effectuée'), findsNothing);
    },
  );

  testWidgets('Future selected dates remain visible but cannot be recorded', (
    WidgetTester tester,
  ) async {
    final today = RenovoDateUtils.normalizeDate(DateTime.now());
    final futureDate = today.add(const Duration(days: 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          confessionsProvider.overrideWith(() => MockConfessionsNotifier()),
          selectedDateProvider.overrideWith(
            () => MockSelectedDateNotifier(futureDate),
          ),
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

    expect(
      find.text(RenovoDateUtils.formatFullFrenchDate(futureDate)),
      findsOneWidget,
    );
    expect(find.text('Marquer comme effectuée'), findsNothing);
    expect(find.text('Ajouter une confession pour ce jour'), findsNothing);

    await tester.tap(find.byTooltip('Nouvel enregistrement'));
    await tester.pumpAndSettle();
    expect(
      find.text(RenovoDateUtils.formatFullFrenchDate(today)),
      findsOneWidget,
    );
  });
}
