import '../entities.dart';
import '../main.dart';
import '../objectbox.g.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  User? _currentUser;
  final userBox = objectbox.store.box<User>();

  User? get currentUser => _currentUser;

  // Set the current user after successful login
  void setCurrentUser(User user) {
    _currentUser = user;
  }

  // Clear current user on logout
  void clearCurrentUser() {
    _currentUser = null;
  }

  // Get current user email
  String getCurrentUserEmail() {
    return _currentUser?.email ?? '';
  }

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Get all users (for debugging)
  List<User> getAllUsers() {
    return userBox.getAll();
  }

  // Get user count (for debugging)
  int getUserCount() {
    return userBox.count();
  }

  // Register a new user
  User registerUser(String email, String password) {
    // Check if user already exists
    final query = userBox.query(User_.email.equals(email)).build();
    final existingUsers = query.find();
    query.close();

    if (existingUsers.isNotEmpty) {
      throw Exception('User with this email already exists');
    }

    // Create new user
    final newUser = User(
      email: email,
      password: password,
    );

    // Store the user and get the ID
    final userId = userBox.put(newUser);
    newUser.id = userId;
    
    print('User registered successfully with ID: $userId');
    print('Total users in database: ${getUserCount()}');
    
    return newUser;
  }

  // Login user and set as current user
  User? loginUser(String email, String password) {
    final query = userBox.query(User_.email.equals(email)).build();
    final users = query.find();
    query.close();

    if (users.isNotEmpty) {
      final user = users.first;
      if (user.password == password) {
        setCurrentUser(user);
        return user;
      }
    }
    return null;
  }

  // Logout current user
  void logout() {
    clearCurrentUser();
  }
}

// Global instance
final userService = UserService(); 