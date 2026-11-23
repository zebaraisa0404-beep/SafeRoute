import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/common.dart';
import '../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> register() async {
    if (isLoading) return;

    final fullName = name.text.trim();
    final emailAddress = email.text.trim();

    if (fullName.isEmpty ||
        emailAddress.isEmpty ||
        password.text.isEmpty ||
        confirm.text.isEmpty) {
      showMessage('Please complete all fields');
      return;
    }

    if (password.text.length < 6) {
      showMessage('Password must be at least 6 characters');
      return;
    }

    if (password.text != confirm.text) {
      showMessage('Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create real user account in Firebase Auth.
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailAddress,
        password: password.text,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Unable to create user account');
      }

      // Save name to Firebase Authentication.
      await user.updateDisplayName(fullName);

      // Save user profile to Cloud Firestore.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': fullName,
        'email': user.email ?? emailAddress,
        'phone': '',
        'role': 'Citizen',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Keep the existing SafeRoute app state.
      appStore.setName(fullName);

      if (!mounted) return;

      showMessage('Registration successful!');
      replace(context, '/roles');
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'weak-password':
          message = 'Please use a stronger password';
          break;
        case 'operation-not-allowed':
          message = 'Enable Email/Password in Firebase';
          break;
        default:
          message = 'Registration failed: ${e.code}';
      }

      showMessage(message);
    } on FirebaseException catch (e) {
      showMessage('Database error: ${e.code}');
    } catch (e) {
      showMessage('Error: $e');
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
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Icon(
              Icons.shield_rounded,
              color: blue,
              size: 70,
            ),
            const SizedBox(height: 15),

            screenTitle(
              'Welcome to SafeRoute',
              subtitle: 'Create your account',
            ),

            const SizedBox(height: 25),

            const Chip(
              label: Text('Citizen Registration'),
            ),

            const SizedBox(height: 10),

            const Text(
              'Responder and Admin access '
              'requires authorization.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            entry('Full Name', name),
            entry('Email Address', email),
            entry('Password', password, hidden: true),
            entry(
              'Confirm Password',
              confirm,
              hidden: true,
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator()
            else
              primaryButton('Register', register),

            TextButton(
              onPressed: isLoading
                  ? null
                  : () => replace(context, '/login'),
              child: const Text(
                'Already have an account? Login',
              ),
            ),
          ],
        ),
      ),
    );
  }
}