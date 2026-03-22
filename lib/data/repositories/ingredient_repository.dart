import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientRepository {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getIngredientByNormalized(
    String normalizedName,
  ) async {
    final snapshot = await _db
        .collection('ingredients')
        .where('normalized_name', isEqualTo: normalizedName)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return snapshot.docs.first.data();
  }

  Future<String?> resolveSynonym(String token) async {
    final snapshot = await _db
        .collection('ingredient_synonyms')
        .where('normalized_synonym', isEqualTo: token)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return snapshot.docs.first.data()['ingredient_id'];
  }
}
