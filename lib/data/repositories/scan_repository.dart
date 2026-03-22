import 'package:cloud_firestore/cloud_firestore.dart';

class ScanRepository {
  final _db = FirebaseFirestore.instance;

  Future<String> createScan(Map<String, dynamic> scan) async {
    final doc = await _db.collection('scan_history').add(scan);
    return doc.id;
  }

  Future<void> saveScanIngredients(List<Map<String, dynamic>> items) async {
    final batch = _db.batch();

    for (var item in items) {
      final ref = _db.collection('scan_ingredients').doc();
      batch.set(ref, item);
    }

    await batch.commit();
  }

  Future<void> saveWarnings(List<Map<String, dynamic>> warnings) async {
    final batch = _db.batch();

    for (var w in warnings) {
      final ref = _db.collection('scan_warnings').doc();
      batch.set(ref, w);
    }

    await batch.commit();
  }
}
