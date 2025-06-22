import 'package:flutter/material.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_page.dart';

class SavedRecipesPage extends StatefulWidget {
  @override
  _SavedRecipesPageState createState() => _SavedRecipesPageState();
}

class _SavedRecipesPageState extends State<SavedRecipesPage> {
  final RecipeService _recipeService = RecipeService();
  List<Map<String, dynamic>> savedRecipes = [];
  bool isLoading = true;

  int _selectedIndex = 1; // This is the Saved tab

  @override
  void initState() {
    super.initState();
    _loadSavedRecipes();
  }

  Future<void> _loadSavedRecipes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final recipes = await _recipeService.getSavedRecipes();
      setState(() {
        savedRecipes = recipes;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading saved recipes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load saved recipes')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        // Already on Saved page
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/s');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/preferences');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final green900 = Colors.green.shade900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Recipes'),
        backgroundColor: green900,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : savedRecipes.isEmpty
              ? const Center(child: Text('No saved recipes found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: savedRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = savedRecipes[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RecipeDetailPage(recipe: recipe),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.white,
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((recipe['imageUrl'] ?? '').toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  recipe['imageUrl'],
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                recipe['name'] ?? 'Unnamed Recipe',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: green900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: green900,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Preferences'),
        ],
      ),
    );
  }
}
