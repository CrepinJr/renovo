import 'package:flutter_test/flutter_test.dart';
import 'package:renovo/data/models/confession.dart';
import 'package:renovo/data/repositories/confession_repository.dart';

void main() {
  group('LocalConfessionRepository', () {
    final futureDate = DateTime.now().add(const Duration(days: 1));
    const errorMessage =
        'Une confession effectuée ne peut pas être enregistrée dans le futur.';

    test('rejects adding a confession dated tomorrow', () async {
      final repository = LocalConfessionRepository();
      final confession = Confession(date: futureDate, parish: 'Saint Joseph');

      await expectLater(
        repository.insertConfession(confession),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            errorMessage,
          ),
        ),
      );
    });

    test('rejects updating a confession dated tomorrow', () async {
      final repository = LocalConfessionRepository();
      final confession = Confession(
        id: 1,
        date: futureDate,
        parish: 'Saint Joseph',
      );

      await expectLater(
        repository.updateConfession(confession),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            errorMessage,
          ),
        ),
      );
    });
  });
}
