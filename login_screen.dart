import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/common.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> login() async {
    if (isLoading) return;

    final emailAddress = email.text.trim();
    final userPassword = password.text;

    if (emailAddress.isEmpty || userPassword.isEmpty) {
      showMessage('Please enter your email and password');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Step 1: Sign in using Firebase Authentication.
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailAddress,
        password: userPassword,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Login failed. User not found.');
      }

      // Step 2: Load profile from Cloud Firestore.
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        showMessage(
          'Your profile was not found in Firestore. '
          'Please contact the administrator.',
        );
        return;
      }

      final userData = userDoc.data();

      final fullName =
          (userData?['name'] as String?) ??
          user.displayName ??
          'SafeRoute User';

      // Step 3: Update existing SafeRoute app state.
      appStore.setName(fullName);

      if (!mounted) return;

      // Step 4: Open existing role selection screen.
      replace(context, '/roles');
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address';
          break;
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'Invalid email or password';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try later';
          break;
        case 'network-request-failed':
          message = 'Please check your internet connection';
          break;
        default:
          message = 'Login failed: ${e.code}';
      }

      showMessage(message);
    } on FirebaseException catch (e) {
      showMessage('Database error: ${e.code}');
    } catch (e) {
      showMessage('Login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pale,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 60),

              const Icon(
                Icons.shield,
                color: blue,
                size: 85,
              ),

              const SizedBox(height: 20),

              screenTitle(
                'Welcome Back',
                subtitle: 'Login to SafeRoute',
              ),

              const SizedBox(height: 50),

              entry('Email Address', email),

              entry(
                'Password',
                password,
                hidden: true,
              ),

              const SizedBox(height: 20),

              if (isLoading)
                const CircularProgressIndicator()
              else
                primaryButton('Login', login),

              const SizedBox(height: 22),

              TextButton(
                onPressed: isLoading
                    ? null
                    : () => go(context, '/register'),
                child: const Text(
                  "Don't have an account? Register",
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Secure login powered by Firebase',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}