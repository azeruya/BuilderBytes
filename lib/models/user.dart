class User {
  final String name;
  final String email;
  final String password;

  User({required this.name, required this.email, required this.password});
}

class DummyUserStore {
  static final List<User> _users = [];

  static bool addUser(User user) {
    // Check if email already exists
    if (_users.any((u) => u.email == user.email)) {
      return false;
    }
    _users.add(user);
    return true;
  }

  static User? authenticate(String email, String password) {
    try {
      return _users.firstWhere(
        (u) => u.email == email && u.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  static List<User> getAllUsers() => _users;
}
