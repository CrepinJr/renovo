import 'package:flutter_test/flutter_test.dart';
import 'package:renovo/core/utils/prediction_calculator.dart';

void main() {
  group('PredictionCalculator - Cycles et alignement au samedi', () {
    test('Cycles de 1 à 4 semaines restent alignés au samedi', () {
      final confessionDate = DateTime(2026, 11, 21);
      for (final weeks in [1, 2, 3, 4]) {
        final interval = Duration(days: weeks * 7);
        final predictions = PredictionCalculator.calculatePredictions(
          latestConfessionDate: confessionDate,
          cycleWeeks: weeks,
        );

        expect(predictions.first, confessionDate.add(interval));
        expect(predictions.first.weekday, DateTime.saturday);
        expect(predictions[1].difference(predictions.first), interval);
        expect(predictions[1].weekday, DateTime.saturday);
        expect(
          PredictionCalculator.statusForDate(
            date: predictions.first,
            completedDates: const [],
            now: predictions.first.add(const Duration(hours: 73)),
          ),
          PredictionStatus.missed,
        );
      }
    });

    test('Une échéance reste en attente à D+71h', () {
      final deadline = DateTime(2026, 12, 12);

      expect(
        PredictionCalculator.statusForDate(
          date: deadline,
          completedDates: const [],
          now: deadline.add(const Duration(hours: 71)),
        ),
        PredictionStatus.upcoming,
      );
    });

    test('Une échéance devient non effectuée après D+72h', () {
      final deadline = DateTime(2026, 12, 12);

      expect(
        PredictionCalculator.statusForDate(
          date: deadline,
          completedDates: const [],
          now: deadline.add(const Duration(hours: 73)),
        ),
        PredictionStatus.missed,
      );
    });

    test('Une confession enregistrée après l’échéance repasse à effectuée', () {
      final deadline = DateTime(2026, 12, 12);

      expect(
        PredictionCalculator.statusForDate(
          date: deadline,
          completedDates: [deadline],
          now: deadline.add(const Duration(hours: 73)),
        ),
        PredictionStatus.completed,
      );
    });

    test('Le cycle suivant reste calculé après une échéance manquée', () {
      final missedDeadline = DateTime(2026, 12, 12);
      final predictions = PredictionCalculator.calculatePredictions(
        latestConfessionDate: DateTime(2026, 11, 21),
        now: missedDeadline.add(const Duration(hours: 73)),
      );

      expect(predictions.first, missedDeadline);
      expect(predictions[1], DateTime(2027, 1, 2));
    });

    test(
      'Retourne une liste vide si aucune confession précédente n’existe',
      () {
        final predictions = PredictionCalculator.calculatePredictions(
          latestConfessionDate: null,
        );
        expect(predictions, isEmpty);
      },
    );

    test('Confession un Samedi : +21 jours retombe exactement un Samedi', () {
      // 21 Novembre 2026 est un Samedi (DateTime.saturday)
      final saturday = DateTime(2026, 11, 21);
      expect(saturday.weekday, DateTime.saturday);

      final predictions = PredictionCalculator.calculatePredictions(
        latestConfessionDate: saturday,
      );

      expect(predictions, isNotEmpty);
      expect(predictions.first.weekday, DateTime.saturday);
      // Le premier samedi suivant doit être exactement 21 jours plus tard
      expect(predictions.first, DateTime(2026, 12, 12));
      expect(predictions.first.difference(saturday).inDays, 21);

      // Toutes les dates prévisionnelles doivent être des Samedis espacées de 21 jours
      for (int i = 0; i < predictions.length; i++) {
        expect(
          predictions[i].weekday,
          DateTime.saturday,
          reason: 'La prédiction #$i doit être un Samedi',
        );
        if (i > 0) {
          expect(
            predictions[i].difference(predictions[i - 1]).inDays,
            21,
            reason: 'Chaque prévision successive doit être espacée de 21 jours',
          );
        }
      }
    });

    test('Confession un Mercredi : retombe systématiquement un Samedi', () {
      // 18 Novembre 2026 est un Mercredi (weekday == 3)
      final wednesday = DateTime(2026, 11, 18);
      expect(wednesday.weekday, DateTime.wednesday);

      final predictions = PredictionCalculator.calculatePredictions(
        latestConfessionDate: wednesday,
      );

      expect(predictions, isNotEmpty);
      // Première prévision : Mercredi + 21j = Mercredi 9 déc -> Samedi le plus proche = 12 déc (+3j)
      expect(predictions.first.weekday, DateTime.saturday);
      expect(predictions.first, DateTime(2026, 12, 12));

      // Vérifie que toutes les prévisions de la liste sont des samedis
      for (final date in predictions) {
        expect(date.weekday, DateTime.saturday);
      }
    });

    test('Confession un Dimanche : retombe systématiquement un Samedi', () {
      // 22 Novembre 2026 est un Dimanche (weekday == 7)
      final sunday = DateTime(2026, 11, 22);
      expect(sunday.weekday, DateTime.sunday);

      final predictions = PredictionCalculator.calculatePredictions(
        latestConfessionDate: sunday,
      );

      expect(predictions, isNotEmpty);
      // Dimanche + 21j = Dimanche 13 déc -> Samedi le plus proche = 12 déc (-1j)
      expect(predictions.first.weekday, DateTime.saturday);
      expect(predictions.first, DateTime(2026, 12, 12));

      for (final date in predictions) {
        expect(date.weekday, DateTime.saturday);
      }
    });

    test('Vérification exhaustive : tous les 7 jours de la semaine retombent sur un Samedi', () {
      // Semaine du Lundi 16 au Dimanche 22 Novembre 2026
      for (int day = 16; day <= 22; day++) {
        final refDate = DateTime(2026, 11, day);
        final predictions = PredictionCalculator.calculatePredictions(
          latestConfessionDate: refDate,
        );

        expect(
          predictions,
          isNotEmpty,
          reason:
              'Les prévisions pour ${refDate.toIso8601String()} ne doivent pas être vides',
        );

        for (final p in predictions) {
          expect(
            p.weekday,
            DateTime.saturday,
            reason:
                'Pour une confession le jour ${refDate.weekday}, la date $p doit être un Samedi',
          );
        }
      }
    });

    test('Horizon de 6 mois : génère environ 8 à 9 occurrences espacées de 21 jours', () {
      final refDate = DateTime(2026, 11, 21);
      final predictions = PredictionCalculator.calculatePredictions(
        latestConfessionDate: refDate,
      );

      // 6 mois = ~182 jours. 182 / 21 ≈ 8-9 cycles.
      expect(predictions.length, inInclusiveRange(8, 10));

      // Vérifie que la dernière date ne dépasse pas l'horizon des 6 mois
      final horizonEnd = DateTime(refDate.year, refDate.month + 6, refDate.day);
      expect(
        predictions.last.isBefore(horizonEnd) ||
            predictions.last.isAtSameMomentAs(horizonEnd),
        isTrue,
      );
    });
  });
}
