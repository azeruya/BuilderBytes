import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Comment {
  final String userId;
  final String userName;
  final String text;
  final Timestamp createdAt;

  Comment({
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      text: data['text'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}

class RecipeDetailPage extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _submitComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _commentController.text.trim().isEmpty) return;

    final recipeId = widget.recipe['id'];

    await FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'text': _commentController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    _commentController.clear();
    _loadComments(); // refresh comments
  }

  Future<void> _loadComments() async {
    final recipeId = widget.recipe['id'];

    final snapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();

    final comments = snapshot.docs.map((doc) => Comment.fromDoc(doc)).toList();

    setState(() {
      _comments = comments;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final ingredients = List<Map<String, dynamic>>.from(recipe['ingredients'] ?? []);
    final steps = List<String>.from(recipe['steps'] ?? []);
    final nutrition = Map<String, dynamic>.from(recipe['nutrition'] ?? {});
    final ingredientNames = List<String>.from(recipe['ingredientNames'] ?? []);

    return Scaffold(
      appBar: AppBar(title: Text(recipe['name'] ?? 'Recipe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((recipe['imageUrl'] ?? '').toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    recipe['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 10),
              Text(recipe['name'] ?? 'Unnamed Recipe',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (recipe['description'] != null)
                Text(recipe['description']),
              const SizedBox(height: 8),
              if (recipe['cuisine'] != null)
                Text("Cuisine: ${recipe['cuisine']}"),
              if (recipe['servings'] != null)
                Text("Servings: ${recipe['servings']} person(s)"),
              const SizedBox(height: 12),

              // Ingredients
              const Text("Ingredient Names:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...ingredientNames.map((name) => Text("- $name")),
              const SizedBox(height: 10),

              const Text("Ingredients:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...ingredients.map((item) => Text("- ${item['quantity']} ${item['name']}")),
              const SizedBox(height: 10),

              // Steps
              const Text("Steps:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...steps.asMap().entries.map((entry) =>
                  Text("${entry.key + 1}. ${entry.value}")),
              const SizedBox(height: 10),

              // Nutrition
              if (nutrition.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Nutrition Info:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...nutrition.entries.map((entry) => Text("${entry.key}: ${entry.value}")),
                  ],
                ),

              const SizedBox(height: 20),
              const Divider(),
              const Text('Leave a comment:', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(hintText: 'Type your comment...'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _submitComment,
                child: const Text('Submit'),
              ),
              const Divider(),

              if (_comments.isNotEmpty) ...[
                const Text('Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._comments.map((c) => ListTile(
                      leading: const Icon(Icons.comment),
                      title: Text(c.userName),
                      subtitle: Text(c.text),
                      trailing: Text(
                        DateFormat('MMM d, h:mm a').format(c.createdAt.toDate()),
                        style: const TextStyle(fontSize: 10),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
