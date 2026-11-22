import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/date_utils.dart';
import '../database/database_helper.dart';
import '../models/confession.dart';

enum ConfessionWriteStatus { completed, pending }

String confessionSignature(Confession confession) => jsonEncode([
  RenovoDateUtils.normalizeDate(confession.date).toIso8601String(),
  confession.parish.trim(),
  confession.notes?.trim().isNotEmpty == true
      ? confession.notes!.trim()
      : null,
]);

abstract interface class ConfessionRepository {
  Future<bool> hasLocalConfessions();
  Future<List<Confession>> getAllConfessions({bool cacheOnly = false});
  Future<List<String>> getDistinctParishes();
  Future<ConfessionWriteStatus> insertConfession(Confession confession);
  Future<ConfessionWriteStatus> updateConfession(Confession confession);
  Future<ConfessionWriteStatus> deleteConfession(Confession confession);
}

class LocalConfessionRepository implements ConfessionRepository {
  LocalConfessionRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  @override
  Future<bool> hasLocalConfessions() => _databaseHelper.hasLocalConfessions();

  @override
  Future<List<Confession>> getAllConfessions({bool cacheOnly = false}) =>
      _databaseHelper.getAllConfessions();

  @override
  Future<List<String>> getDistinctParishes() =>
      _databaseHelper.getDistinctParishes();

  Future<void> addConfessionsIfAbsent(Iterable<Confession> confessions) async {
    final knownSignatures = {
      for (final confession in await getAllConfessions())
        confessionSignature(confession),
    };

    for (final confession in confessions) {
      if (!knownSignatures.add(confessionSignature(confession))) continue;
      await _databaseHelper.insertConfession(
        Confession(
          date: confession.date,
          parish: confession.parish,
          notes: confession.notes,
          createdAt: confession.createdAt,
        ),
      );
    }
  }

  @override
  Future<ConfessionWriteStatus> insertConfession(Confession confession) async {
    await _databaseHelper.insertConfession(confession);
    return ConfessionWriteStatus.completed;
  }

  @override
  Future<ConfessionWriteStatus> updateConfession(
    Confession confession,
  ) async {
    final id = confession.id;
    if (id == null) {
      throw StateError('A local confession must have an ID before updating.');
    }
    await _databaseHelper.updateConfession(confession);
    return ConfessionWriteStatus.completed;
  }

  @override
  Future<ConfessionWriteStatus> deleteConfession(
    Confession confession,
  ) async {
    final id = confession.id;
    if (id == null) {
      throw StateError('A local confession must have an ID before deleting.');
    }
    await _databaseHelper.deleteConfession(id);
    return ConfessionWriteStatus.completed;
  }
}

class FirestoreConfessionRepository implements ConfessionRepository {
  FirestoreConfessionRepository({
    required this.uid,
    FirebaseFirestore? firestore,
    DatabaseHelper? databaseHelper,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final String uid;
  final FirebaseFirestore _firestore;
  final DatabaseHelper _databaseHelper;

  CollectionReference<Map<String, dynamic>> get _confessions =>
      _confessionsFor(uid);

  CollectionReference<Map<String, dynamic>> _confessionsFor(String userId) =>
      _firestore.collection('users').doc(userId).collection('confessions');

  @override
  Future<List<Confession>> getAllConfessions({
    bool cacheOnly = false,
  }) async {
    final snapshot = await _confessions.get(
      cacheOnly ? const GetOptions(source: Source.cache) : null,
    );
    final confessions = snapshot.docs.map(_fromDocument).toList();
    confessions.sort((a, b) {
      final dateOrder = b.normalizedDate.compareTo(a.normalizedDate);
      if (dateOrder != 0) return dateOrder;
      return b.createdAt.compareTo(a.createdAt);
    });
    return confessions;
  }

  @override
  Future<List<String>> getDistinctParishes() async {
    final confessions = await getAllConfessions();
    return confessions
        .map((confession) => confession.parish.trim())
        .where((parish) => parish.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  Future<ConfessionWriteStatus> insertConfession(
    Confession confession,
  ) async {
    return _awaitCloudWrite(
      _confessions.doc(_documentId(confession)).set(_toDocument(confession)),
    );
  }

  @override
  Future<ConfessionWriteStatus> updateConfession(
    Confession confession,
  ) async {
    final oldId = confession.remoteId;
    if (oldId == null) {
      throw StateError('A cloud confession must have a document ID to update.');
    }

    final newId = _documentId(confession);
    final batch = _firestore.batch()
      ..set(_confessions.doc(newId), _toDocument(confession));
    if (newId != oldId) {
      batch.delete(_confessions.doc(oldId));
    }
    return _awaitCloudWrite(batch.commit());
  }

  @override
  Future<ConfessionWriteStatus> deleteConfession(
    Confession confession,
  ) async {
    final remoteId = confession.remoteId;
    if (remoteId == null) {
      throw StateError('A cloud confession must have a document ID to delete.');
    }
    return _awaitCloudWrite(_confessions.doc(remoteId).delete());
  }

  @override
  Future<bool> hasLocalConfessions() => _databaseHelper.hasLocalConfessions();

  Future<void> migrateLocalToCloud(String uid) async {
    if (uid != this.uid) {
      throw ArgumentError.value(uid, 'uid', 'Does not match this repository.');
    }

    final localConfessions = await _databaseHelper.getAllConfessions();
    if (localConfessions.isEmpty) return;

    final collection = _confessionsFor(uid);
    final existingSnapshot = await collection.get();
    final signatures = <String>{
      for (final document in existingSnapshot.docs)
        confessionSignature(_fromDocument(document)),
    };

    var batch = _firestore.batch();
    var batchSize = 0;
    for (final confession in localConfessions) {
      final signature = confessionSignature(confession);
      if (!signatures.add(signature)) continue;

      batch.set(
        collection.doc(_documentId(confession)),
        _toDocument(confession),
      );
      batchSize++;
      if (batchSize == 450) {
        await batch.commit();
        batch = _firestore.batch();
        batchSize = 0;
      }
    }

    if (batchSize > 0) {
      await batch.commit();
    }
    await _databaseHelper.clearAllConfessions();
    await _databaseHelper.saveSetting(
      _lastSyncSettingKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> syncNow() async {
    if (await hasLocalConfessions()) {
      await migrateLocalToCloud(uid);
    }
    await _firestore.waitForPendingWrites();
    await _confessions.get(const GetOptions(source: Source.server));
    await _databaseHelper.saveSetting(
      _lastSyncSettingKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<DateTime?> getLastSyncedAt() async {
    final value = await _databaseHelper.getSetting(_lastSyncSettingKey);
    return value == null ? null : DateTime.parse(value);
  }

  Confession _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final date = _readDate(data['date']);
    final createdAtValue = data['createdAt'] ?? data['created_at'];
    return Confession(
      remoteId: document.id,
      date: date,
      parish: data['parish'] as String,
      notes: data['notes'] as String?,
      createdAt: createdAtValue == null ? date : _readDate(createdAtValue),
    );
  }

  Map<String, dynamic> _toDocument(Confession confession) => {
    'date': RenovoDateUtils.normalizeDate(confession.date).toIso8601String(),
    'parish': confession.parish.trim(),
    'notes': confession.notes?.trim(),
    'createdAt': Timestamp.fromDate(confession.createdAt),
  };

  DateTime _readDate(Object value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    throw FormatException('Unsupported confession date value: $value');
  }

  String _documentId(Confession confession) =>
      sha256.convert(utf8.encode(confessionSignature(confession))).toString();

  String get _lastSyncSettingKey => 'last_sync_$uid';

  Future<ConfessionWriteStatus> _awaitCloudWrite(Future<void> write) async {
    var timedOut = false;
    final observedWrite = write.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        if (timedOut) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              context: ErrorDescription(
                'Firestore confession write failed after the UI timeout',
              ),
            ),
          );
        }
        Error.throwWithStackTrace(error, stackTrace);
      },
    );

    await observedWrite.timeout(
      const Duration(milliseconds: 500),
      onTimeout: () {
        timedOut = true;
      },
    );
    return timedOut
        ? ConfessionWriteStatus.pending
        : ConfessionWriteStatus.completed;
  }
}
