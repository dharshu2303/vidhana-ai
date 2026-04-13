import 'package:flutter/material.dart';

class AuthUser {
  final String email;
  final String name;
  final String role;
  final String badgeNo;
  final String policeStation;
  final String complainantName;

  const AuthUser({
    required this.email,
    required this.name,
    required this.role,
    required this.badgeNo,
    this.policeStation = '',
    this.complainantName = '',
  });

  AuthUser copyWith({
    String? policeStation,
    String? complainantName,
  }) {
    return AuthUser(
      email: email,
      name: name,
      role: role,
      badgeNo: badgeNo,
      policeStation: policeStation ?? this.policeStation,
      complainantName: complainantName ?? this.complainantName,
    );
  }
}

class AuthService extends ChangeNotifier {
  AuthUser? _currentUser;
  bool _isLoading = false;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  // Mock user database
  static const _mockUsers = {
    'priya': {
      'password': 'priya006',
      'name': 'Priya Sharma',
      'role': 'Constable',
      'badgeNo': 'TN-4521',
      'policeStation': 'Anna Nagar Police Station',
    },
    'admin@vidhana.ai': {
      'password': 'admin123',
      'name': 'Rajesh Kumar',
      'role': 'Inspector',
      'badgeNo': 'TN-1001',
      'policeStation': 'T. Nagar Police Station',
    },
  };

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final user = _mockUsers[email.trim().toLowerCase()];
    if (user != null && user['password'] == password) {
      _currentUser = AuthUser(
        email: email.trim().toLowerCase(),
        name: user['name']!,
        role: user['role']!,
        badgeNo: user['badgeNo']!,
        policeStation: user['policeStation'] ?? '',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void updateProfile({String? policeStation, String? complainantName}) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      policeStation: policeStation,
      complainantName: complainantName,
    );
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
