import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Cream background to match the logo's background
          color: const Color(0xFFF5F5DC),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Admin button in top right corner
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade900.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.green.shade900.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin_login');
                    },
                    icon: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.green.shade900,
                      size: 24,
                    ),
                    tooltip: 'Admin Login',
                  ),
                ),
              ),

              // Main content centered
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo container with rounded square shape
                    Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.green.shade900,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      // Logo content with chef hat, carrot and checklist
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Chef hat
                          Positioned(
                            top: 35,
                            child: Icon(
                              Icons.restaurant,
                              size: 60,
                              color: const Color(0xFFF5F5DC),
                            ),
                          ),
                          // Carrot
                          Positioned(
                            bottom: 40,
                            left: 45,
                            child: Transform.rotate(
                              angle: -0.4,
                              child: Icon(
                                Icons.eco,
                                size: 50,
                                color: const Color(0xFFF5F5DC),
                              ),
                            ),
                          ),
                          // Checklist
                          Positioned(
                            bottom: 40,
                            right: 45,
                            child: Transform.rotate(
                              angle: 0.2,
                              child: Icon(
                                Icons.fact_check,
                                size: 50,
                                color: const Color(0xFFF5F5DC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Name
                    Text(
                      'PantryPal',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tagline
                    Text(
                      'Your Ingredients, Endless Possibilities',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Get Started Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFFF5F5DC), // Text color
                        backgroundColor: Colors.green.shade900, // Button color
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register Button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade900, // Text color
                        side: BorderSide(
                          color: Colors.green.shade900,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Browse as Guest option
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/home');
                      },
                      child: Text(
                        'Browse as Guest',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
