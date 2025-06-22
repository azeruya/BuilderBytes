import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PreferencePage extends StatefulWidget {
  const PreferencePage({Key? key}) : super(key: key);

  @override
  State<PreferencePage> createState() => _PreferencePageState();
}

class _PreferencePageState extends State<PreferencePage> {
  final _formKey = GlobalKey<FormState>();

  final List<String> cuisines = ['Malay', 'Chinese', 'Indian', 'Western', 'Italian', 'None'];
  final List<String> diets = ['None', 'Vegetarian', 'Vegan', 'Keto'];

  String? selectedCuisine;
  String? selectedDiet;
  String allergies = "";

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final prefs = doc.data()?['preferences'];
      if (prefs != null) {
        setState(() {
          selectedCuisine = prefs['cuisine'];
          selectedDiet = prefs['diet'];
          allergies = (prefs['allergies'] as List<dynamic>).join(',');
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    if (user == null) return;

    final prefData = {
      'cuisine': selectedCuisine ?? '',
      'diet': selectedDiet ?? '',
      'allergies': allergies
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({'preferences': prefData}, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Preferences'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedCuisine,
                decoration: const InputDecoration(labelText: 'Preferred Cuisine'),
                items: cuisines.map((String value) {
                  return DropdownMenuItem(value: value, child: Text(value));
                }).toList(),
                onChanged: (value) => setState(() => selectedCuisine = value),
                validator: (value) =>
                    value == null ? 'Please select a cuisine' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedDiet,
                decoration: const InputDecoration(labelText: 'Diet Type'),
                items: diets.map((String value) {
                  return DropdownMenuItem(value: value, child: Text(value));
                }).toList(),
                onChanged: (value) => setState(() => selectedDiet = value),
                validator: (value) =>
                    value == null ? 'Please select a diet' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: allergies,
                decoration: const InputDecoration(
                    labelText: 'Allergies (comma-separated)'),
                onChanged: (value) => allergies = value,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _savePreferences();
                  }
                },
                child: const Text('Save Preferences'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
