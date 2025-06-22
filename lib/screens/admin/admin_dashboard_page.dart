import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/*
class AdminRecipe {
  final String id;
  final String title;
  final String author;
  final DateTime createdDate;
  final int views;
  final double rating;
  final bool isApproved;

  AdminRecipe({
    required this.id,
    required this.title,
    required this.author,
    required this.createdDate,
    required this.views,
    required this.rating,
    required this.isApproved,
  });
}*/

class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> ingredientNames;
  final List<String> steps;
  final Map<String, dynamic> nutrition;
  final String cuisine;
  final List<String> dietTags;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.ingredientNames,
    required this.steps,
    required this.nutrition,
    required this.cuisine,
    required this.dietTags,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      ingredientNames: List<String>.from(data['ingredientNames'] ?? []),
      steps: List<String>.from(data['steps'] ?? []),
      nutrition: data['nutrition'] ?? {},
      cuisine: data['cuisine'] ?? '',
      dietTags: List<String>.from(data['dietTags'] ?? []),
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<Recipe> allRecipes = [];
  List<Recipe> recentRecipes = [];
  List<Recipe> savedRecipes = [];
  Recipe? recipeOfTheDay;

  int _totalUsers = 0;
  int _totalRecipes = 0;

  List<Map<String, dynamic>> _mostSavedRecipes = [];

  @override
void initState() {
    super.initState();
    _fetchRecipes();
    _fetchAdminStats();
    _loadMostSavedRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Welcome back, Admin!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                FloatingActionButton(
                  onPressed: () => _showAddRecipeDialog(context),
                  backgroundColor: Colors.red.shade700,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Admin Stats Section
            _buildSectionTitle('Dashboard Overview'),
            _buildAdminStats(),
            const SizedBox(height: 20),

            if (recipeOfTheDay != null) ...[
              _buildSectionTitle('Recipe of the Day'),
              _buildHighlightCard(recipeOfTheDay!),
              const SizedBox(height: 20),
            ],

            if (_mostSavedRecipes.isNotEmpty) ...[
            _buildSectionTitle('Most Saved Recipes'),
            ..._mostSavedRecipes.map((recipe) => ListTile(
                  leading: const Icon(Icons.favorite),
                  title: Text(recipe['name']),
                  trailing: Text('${recipe['count']} saves'),
                )),
          ],

            if (recentRecipes.isNotEmpty) ...[
              _buildSectionTitle('Recently Added'),
              _buildHorizontalList(recentRecipes),
              const SizedBox(height: 20),
            ],

            if (savedRecipes.isNotEmpty) ...[
              _buildSectionTitle('Pending Review'),
              _buildHorizontalList(savedRecipes),
              const SizedBox(height: 20),
            ],

            if (allRecipes.isNotEmpty) ...[
              _buildSectionTitle('All Admin Recipes'),
              _buildAllRecipesList(allRecipes),
            ],

            if (allRecipes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No admin recipes yet!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        'Tap the + button to add your first admin recipe',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStats() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(
          title: 'Total Users',
          value: _totalUsers.toString(),
          icon: Icons.person,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Total Recipes',
          value: _totalRecipes.toString(),
          icon: Icons.book,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRecipeDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final ingredientNamesController = TextEditingController();
    final stepsController = TextEditingController();
    final caloriesController = TextEditingController();
    final fatController = TextEditingController();
    final proteinController = TextEditingController();
    final cuisineController = TextEditingController();
    final dietTagsController = TextEditingController();
    final servingsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    'Add New Admin Recipe',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(titleController, 'Title', 'Enter recipe title'),
                  _buildTextField(descriptionController, 'Description', 'Enter description'),
                  _buildTextField(ingredientNamesController, 'Ingredients (comma-separated)', 'e.g., onion, garlic, salt'),
                  _buildTextField(stepsController, 'Steps (comma-separated)', 'e.g., Mix, Cook, Serve'),
                  _buildTextField(cuisineController, 'Cuisine', 'e.g., Italian, Malaysian'),
                  _buildTextField(dietTagsController, 'Diet Tags (comma-separated)', 'e.g., vegan, low-carb'),
                  _buildTextField(servingsController, 'Servings', 'e.g., 2', keyboardType: TextInputType.number),

                  const SizedBox(height: 16),
                  const Text('Nutrition Info', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildTextField(caloriesController, 'Calories', 'e.g., 200', keyboardType: TextInputType.number),
                  _buildTextField(fatController, 'Fat', 'e.g., 10', keyboardType: TextInputType.number),
                  _buildTextField(proteinController, 'Protein', 'e.g., 15', keyboardType: TextInputType.number),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _saveRecipe(
                          context,
                          title: titleController.text,
                          description: descriptionController.text,
                          ingredientNames: ingredientNamesController.text,
                          steps: stepsController.text,
                          cuisine: cuisineController.text,
                          dietTags: dietTagsController.text,
                          servings: servingsController.text,
                          calories: caloriesController.text,
                          fat: fatController.text,
                          protein: proteinController.text,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Recipe'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _loadMostSavedRecipes() async {
    final result = await _getMostSavedRecipesReport();
    print('Most saved recipes loaded: $result'); // <-- DEBUG LOG
    setState(() {
      _mostSavedRecipes = result;
    });
  }

  Future<void> _fetchRecipes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Recipe> loaded = snapshot.docs
          .map((doc) => Recipe.fromFirestore(doc))
          .toList();

      setState(() {
        allRecipes = loaded;
        recentRecipes = loaded.take(3).toList();
        if (loaded.isNotEmpty) {
          recipeOfTheDay = loaded.first;
        }
      });
    } catch (e) {
      print('❌ Error fetching recipes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load recipes')),
      );
    }
  }

  Future<void> _fetchAdminStats() async {
    try {
      // Get total users
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      _totalUsers = usersSnapshot.docs.length;

      // Get total recipes
      final recipesSnapshot = await FirebaseFirestore.instance.collection('recipes').get();
      _totalRecipes = recipesSnapshot.docs.length;

      if (mounted) {
        setState(() {}); // Trigger UI update
      }
    } catch (e) {
      debugPrint('Error fetching admin stats: $e');
    }
  }

  void _saveRecipe(
    BuildContext context, {
    required String title,
    required String description,
    required String ingredientNames,
    required String steps,
    required String cuisine,
    required String dietTags,
    required String servings,
    required String calories,
    required String fat,
    required String protein,
  }) async {
    if (title.trim().isEmpty || description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Description are required.')),
      );
      return;
    }

    try {
      final now = Timestamp.now();

      final List<String> parsedIngredients = ingredientNames
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final List<String> parsedSteps = steps
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final List<String> parsedTags = dietTags
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final Map<String, dynamic> nutrition = {
        'calories': int.tryParse(calories) ?? 0,
        'fat': int.tryParse(fat) ?? 0,
        'protein': int.tryParse(protein) ?? 0,
      };

      final recipeData = {
        'name': title.trim(),
        'description': description.trim(),
        'imageUrl': '', // Optional image upload can be implemented later
        'ingredientNames': parsedIngredients,
        'ingredients': [], // Optional
        'steps': parsedSteps,
        'cuisine': cuisine.trim(),
        'dietTags': parsedTags,
        'servings': int.tryParse(servings) ?? 1,
        'nutrition': nutrition,
        'createdAt': now,
      };

      await FirebaseFirestore.instance.collection('recipes').add(recipeData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe "$title" added successfully.'),
            backgroundColor: Colors.red.shade700,
          ),
        );

        _fetchRecipes(); // Optional if you're displaying the updated list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save recipe. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, int>> _fetchSavedRecipeCounts() async {
  final firestore = FirebaseFirestore.instance;
  final usersSnapshot = await firestore.collection('users').get();

  final Map<String, int> recipeCounts = {};

  for (final userDoc in usersSnapshot.docs) {
    final savedRecipesSnapshot = await firestore
        .collection('users')
        .doc(userDoc.id)
        .collection('savedRecipes')
        .get();

    for (final recipeDoc in savedRecipesSnapshot.docs) {
      final recipeId = recipeDoc.id;
      recipeCounts[recipeId] = (recipeCounts[recipeId] ?? 0) + 1;
    }
  }

  print('Fetched save counts: $recipeCounts'); // DEBUG
  return recipeCounts;
}

Future<List<Map<String, dynamic>>> _getMostSavedRecipesReport() async {
  final saveCounts = await _fetchSavedRecipeCounts();
  final firestore = FirebaseFirestore.instance;

  final recipeList = <Map<String, dynamic>>[];

  for (final entry in saveCounts.entries) {
    final recipeId = entry.key;
    final count = entry.value;

    final recipeDoc =
        await firestore.collection('recipes').doc(recipeId).get();

    if (recipeDoc.exists) {
      final data = recipeDoc.data()!;
      recipeList.add({
        'name': data['name'],
        'count': count,
      });
    }
  }

  recipeList.sort((a, b) => b['count'].compareTo(a['count']));
  return recipeList;
}


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildHighlightCard(Recipe recipe) {
    return Card(
      color: Colors.red.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.star, size: 30, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recipe.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeGrid(List<Recipe> recipes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recipes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return Card(
          color: Colors.red.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              recipes[index].title,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalList(List<Recipe> recipes) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Card(
            color: Colors.orange.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  recipes[index].title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllRecipesList(List<Recipe> recipes) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ExpansionTile(
            title: Text(
              recipe.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recipe.ingredientNames.isNotEmpty) ...[
                      const Text(
                        'Ingredients:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(recipe.ingredientNames.join(', ')),
                      const SizedBox(height: 12),
                    ],
                    if (recipe.steps.isNotEmpty) ...[
                      const Text(
                        'Instructions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(recipe.steps.join('\n')),
                      const SizedBox(height: 12),
                    ],
                    if (recipe.nutrition.isNotEmpty) ...[
                      const Text(
                        'Nutrition Facts:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.nutrition.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join('\n'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/admin_login');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}