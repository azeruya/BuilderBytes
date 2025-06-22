import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveRecipe(String recipeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid)
        .collection('savedRecipes').doc(recipeId)
        .set({'savedAt': FieldValue.serverTimestamp()});
  }

  Future<void> unsaveRecipe(String recipeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid)
        .collection('savedRecipes').doc(recipeId)
        .delete();
  }

  Future<bool> isRecipeSaved(String recipeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _firestore.collection('users').doc(uid)
        .collection('savedRecipes').doc(recipeId).get();
    return doc.exists;
  }

  Future<List<Map<String, dynamic>>> getSavedRecipes() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final savedDocs = await _firestore.collection('users').doc(uid)
        .collection('savedRecipes').get();

    List<Map<String, dynamic>> savedRecipes = [];
    for (var doc in savedDocs.docs) {
      final recipeDoc = await _firestore.collection('recipes').doc(doc.id).get();
      if (recipeDoc.exists) {
        final data = recipeDoc.data()!;
        data['id'] = recipeDoc.id;
        savedRecipes.add(data);
      }
    }
    return savedRecipes;
  }
}
