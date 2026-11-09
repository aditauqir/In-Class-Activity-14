import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'authentication_screen.dart';
import 'products_screen.dart';

class AuthGate extends StatelessWidget {
  final AuthService _authService;

  AuthGate({super.key, AuthService? authService})
      : _authService = authService ?? AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('Unable to check sign-in status. Try again.')),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return ProductsScreen(authService: _authService);
        } else {
          return AuthenticationScreen(authService: _authService);
        }},
    );
  }
}
