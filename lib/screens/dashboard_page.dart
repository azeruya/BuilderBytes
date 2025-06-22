import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_detail_page.dart';
import '../services/recipe_service.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  User? currentUser;
  String name = 'User';
  List<Map<String, dynamic>> recipes = [];
  bool isLoading = true;
  String searchQuery = '';

  Map<String, bool> savedStatus = {}; // recipeId -> isSaved
  final RecipeService _recipeService = RecipeService();

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRecipes();
  }

  void _loadUserData() {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        name = currentUser!.displayName ?? currentUser!.email ?? 'User';
      });
    }
  }

  Future<void> _loadRecipes() async {
  setState(() {
    isLoading = true;
  });

  try {
    currentUser = FirebaseAuth.instance.currentUser;
    List<Map<String, dynamic>> loadedRecipes = [];
    Map<String, bool> savedMap = {};

    // Fetch all recipes
    final allRecipesSnapshot =
        await FirebaseFirestore.instance.collection('recipes').get();

    // Fetch user preferences (optional)
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final userData = userDoc.data();

    // Default values
    final prefs = userData?['preferences'] ?? {};
    final List<dynamic> allergies = prefs['allergies'] ?? [];
    final String? userCuisine = prefs['cuisine'];
    final String? userDiet = prefs['diet']; // optional

    print('✅ Loaded Preferences (if any)');
    print('   Allergies: $allergies');
    print('   Cuisine: $userCuisine');
    print('   Diet: $userDiet');

    final userCuisineNormalized = (userCuisine ?? '').toLowerCase().trim();
    final userDietNormalized = (userDiet ?? '').toLowerCase().trim();

    for (var doc in allRecipesSnapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;

      final List<dynamic> ingredients = data['ingredientNames'] ?? [];
      final String recipeCuisine =
          (data['cuisine'] ?? '').toString().toLowerCase().trim();
      final List<dynamic> dietTags = (data['dietTags'] ?? []).map((e) => e.toString().toLowerCase().trim()).toList();

      print('🔍 Recipe: ${data['name']} | Cuisine: $recipeCuisine | Ingredients: $ingredients | Diet Tags: $dietTags');

      // FILTER 1: Skip recipes containing allergens
      bool containsAllergen = allergies.any((allergy) {
        return ingredients.any((ingredient) =>
            ingredient.toString().toLowerCase().contains(allergy.toString().toLowerCase()));
      });

      if (containsAllergen) {
        print('🚫 Skipped due to allergen: ${data['name']}');
        continue;
      }

      // FILTER 2: Skip if cuisine doesn't match (only if cuisine is set)
      if (userCuisineNormalized.isNotEmpty &&
          userCuisineNormalized != 'none' &&
          recipeCuisine != userCuisineNormalized) {
        print('🚫 Skipped due to cuisine mismatch: ${data['name']}');
        continue;
      }

      // FILTER 3: Skip if diet tag doesn't match (only if diet is set)
      if (userDietNormalized.isNotEmpty &&
          userDietNormalized != 'none' &&
          !dietTags.contains(userDietNormalized)) {
        print('🚫 Skipped due to diet mismatch: ${data['name']}');
        continue;
      }

      // Passed all filters
      print('✅ Included: ${data['name']}');
      loadedRecipes.add(data);
    }

    // Check which recipes are saved
    for (var recipe in loadedRecipes) {
      final isSaved = await _recipeService.isRecipeSaved(recipe['id']);
      savedMap[recipe['id']] = isSaved;
    }

    setState(() {
      recipes = loadedRecipes;
      savedStatus = savedMap;
      isLoading = false;
    });

    print('📦 FINAL LOADED RECIPES COUNT: ${loadedRecipes.length}');
  } catch (e) {
    print('❌ Error loading recipes: $e');
    setState(() {
      recipes = [];
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to load recipes")),
    );
  }
}

  Future<void> _searchRecipes(String query) async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('ingredientNames', arrayContains: query.toLowerCase())
          .get();

      final filteredRecipes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        recipes = filteredRecipes;
        isLoading = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search failed')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/saved');
        break;
      case 2:
        Navigator.pushNamed(context, '/preferences').then((_) {
          _loadRecipes();
        });
        break;
    }
  }

  void _toggleSaveRecipe(String recipeId) async {
    final isCurrentlySaved = savedStatus[recipeId] ?? false;

    try {
      if (isCurrentlySaved) {
        await _recipeService.unsaveRecipe(recipeId);
      } else {
        await _recipeService.saveRecipe(recipeId);
      }

      setState(() {
        savedStatus[recipeId] = !isCurrentlySaved;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${isCurrentlySaved ? 'unsave' : 'save'} recipe')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final creamColor = const Color(0xFFFFFEF7);
    final green900 = Colors.green.shade900;

    return Scaffold(
      backgroundColor: creamColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: green900,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'User Profile',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/user_profile');
            },
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Welcome, $name!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: green900,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search by ingredient',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                searchQuery = value.trim();
                if (searchQuery.isEmpty) {
                  _loadRecipes();
                } else {
                  _searchRecipes(searchQuery.toLowerCase());
                }
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : recipes.isEmpty
                    ? const Center(child: Text("No recipes found"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeDetailPage(recipe: recipe),
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                recipe['name'] ?? 'Unnamed Recipe',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: green900,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                savedStatus[recipe['id']] == true
                                                    ? Icons.bookmark
                                                    : Icons.bookmark_border,
                                                color: green900,
                                              ),
                                              onPressed: () => _toggleSaveRecipe(recipe['id']),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        if (recipe['description'] != null)
                                          Text(
                                            recipe['description'],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey[700]),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: green900,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Preferences'),
        ],
        backgroundColor: Colors.white,
        showUnselectedLabels: true,
      ),
    );
  }
}
