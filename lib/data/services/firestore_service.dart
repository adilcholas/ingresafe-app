import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static late FirebaseFirestore db;

  static Future<void> initialize() async {
    db = FirebaseFirestore.instance;

    db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  static CollectionReference<Map<String, dynamic>> collection(String path) {
    return db.collection(path);
  }

  static DocumentReference<Map<String, dynamic>> doc(String path) {
    return db.doc(path);
  }
}