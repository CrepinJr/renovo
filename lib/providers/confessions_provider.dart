import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_utils.dart';
import '../data/database/database_helper.dart';
import '../data/models/confession.dart';

/// Modern Riverpod AsyncNotifier managing the list of confessions.
class ConfessionsNotifier extends AsyncNotifier<List<Confession>> {
  @override
  Future<List<Confession>> build() async {
    return await DatabaseHelper.instance.getAllConfessions();
  }

  Future<void> refreshConfessions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await DatabaseHelper.instance.getAllConfessions();
    });
  }

  Future<void> addConfession({
    required DateTime date,
    required String parish,
    String? notes,
  }) async {
    final confession = Confession(
      date: RenovoDateUtils.normalizeDate(date),
      parish: parish,
      notes: notes,
    );
    await DatabaseHelper.instance.insertConfession(confession);
    await refreshConfessions();
  }

  Future<void> updateConfession(Confession confession) async {
    await DatabaseHelper.instance.updateConfession(confession);
    await refreshConfessions();
  }

  Future<void> deleteConfession(int id) async {
    await DatabaseHelper.instance.deleteConfession(id);
    await refreshConfessions();
  }
}

/// Main confessions provider.
final confessionsProvider =
    AsyncNotifierProvider<ConfessionsNotifier, List<Confession>>(
  ConfessionsNotifier.new,
);

/// Provider returning the most recent effective confession (by date), or null.
final latestConfessionProvider = Provider<Confession?>((ref) {
  final confessionsAsync = ref.watch(confessionsProvider);
  return confessionsAsync.when(
    data: (list) {
      if (list.isEmpty) return null;
      return list.first; // SQLite query orders by date DESC
    },
    loading: () => null,
    error: (e, st) => null,
  );
});

/// Map of normalized DateTime -> Confession for instant O(1) day inspection in calendar.
final confessionsMapProvider = Provider<Map<DateTime, Confession>>((ref) {
  final confessionsAsync = ref.watch(confessionsProvider);
  final map = <DateTime, Confession>{};

  confessionsAsync.whenData((list) {
    for (final c in list) {
      map.putIfAbsent(c.normalizedDate, () => c);
    }
  });

  return map;
});

/// Provider for distinct parish names for autocomplete suggestions.
final parishesProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(confessionsProvider);
  return await DatabaseHelper.instance.getDistinctParishes();
});
