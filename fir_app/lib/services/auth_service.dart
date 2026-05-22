import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AuthUser? _currentUser;
  bool _isLoading = false;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  // Listen to auth state changes when service starts
  AuthService() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _fetchUserProfile(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = AuthUser(
          email: _auth.currentUser!.email ?? '',
          name: data['name'] ?? '',
          role: data['role'] ?? '',
          badgeNo: data['badgeNo'] ?? '',
          policeStation: data['policeStation'] ?? '',
          complainantName: data['complainantName'] ?? '',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
  }

  // LOGIN
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password,
      );
      // _fetchUserProfile triggers automatically thanks to the listener
      _isLoading = false;
      return true;
    } catch (e) {
      debugPrint("Login Failed: \$e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // SIGN UP (Create Account and sync data to Firestore Database)
  Future<bool> register(String email, String password, String name, String role, String badgeNo) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Store additional user details in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email.trim(),
        'name': name,
        'role': role,
        'badgeNo': badgeNo,
        'policeStation': '',
        'complainantName': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      return true;
    } catch (e) {
      debugPrint("Registration Failed: \$e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({String? policeStation, String? complainantName}) async {
    if (_currentUser == null) return;
    
    // Update local state
    _currentUser = _currentUser!.copyWith(
      policeStation: policeStation,
      complainantName: complainantName,
    );
    notifyListeners();

    // Sync to Firestore
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).update({
          if (policeStation != null) 'policeStation': policeStation,
          if (complainantName != null) 'complainantName': complainantName,
        });
      }
    } catch (e) {
      debugPrint("Failed to sync profile update: \$e");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
