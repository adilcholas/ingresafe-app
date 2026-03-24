import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/scan_result.dart';

/// Handles persisting and loading scan history from Firestore.
/// Collection: `scan_history`  — one document per scan.
class ScanHistoryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _collection = 'scan_history';

  // ── Save ───────────────────────────────────────────────────────────────────

  /// Saves a scan to Firestore and returns the updated [ScanResult] with its
  /// Firestore document ID attached.
  static Future<ScanResult> saveScan(ScanResult scan) async {
    try {
      final docRef = await _db.collection(_collection).add(scan.toMap());
      debugPrint('[ScanHistory] Saved scan: ${docRef.id}');
      return scan.copyWith(firestoreId: docRef.id);
    } catch (e) {
      debugPrint('[ScanHistory] Save error: $e');
      return scan; // return original if Firestore fails
    }
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  /// Loads the most recent [limit] scans, ordered newest-first.
  static Future<List<ScanResult>> loadHistory({int limit = 50}) async {
    try {
      final snap = await _db
          .collection(_collection)
          .orderBy('scannedAt', descending: true)
          .limit(limit)
          .get();

      final results = snap.docs
          .map((doc) => ScanResult.fromMap(doc.id, doc.data()))
          .toList();

      debugPrint('[ScanHistory] Loaded ${results.length} scans from Firestore.');
      return results;
    } catch (e) {
      debugPrint('[ScanHistory] Load error: $e');
      return [];
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Deletes a single scan document.
  static Future<void> deleteScan(String firestoreId) async {
    try {
      await _db.collection(_collection).doc(firestoreId).delete();
      debugPrint('[ScanHistory] Deleted scan: $firestoreId');
    } catch (e) {
      debugPrint('[ScanHistory] Delete error: $e');
    }
  }

  /// Clears **all** scan history documents for the current user.
  static Future<void> clearHistory() async {
    try {
      final snap = await _db.collection(_collection).get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('[ScanHistory] Cleared ${snap.docs.length} history records.');
    } catch (e) {
      debugPrint('[ScanHistory] Clear error: $e');
    }
  }
}
