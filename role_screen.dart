import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/common.dart';
import 'admin_screen.dart';

// Read the role of the signed-in user.
Future<String?> getCurrentUserRole() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return null;

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!snapshot.exists) return null;

  return snapshot.data()?['role'] as String?;
}

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  late final Future<String?> roleFuture;

  @override
  void initState() {
    super.initState();
    roleFuture = getCurrentUserRole();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    replace(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pale,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: FutureBuilder<String?>(
              future: roleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load your role: '
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final role = snapshot.data;
                final isLoggedIn =
                    FirebaseAuth.instance.currentUser != null;

                final isAdmin =
                    isLoggedIn && role == 'Admin';

                final canUseApp =
                    isLoggedIn && role != null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 25),

                      const Icon(
                        Icons.shield_rounded,
                        color: blue,
                        size: 80,
                      ),

                      const SizedBox(height: 15),

                      screenTitle(
                        'Welcome to SafeRoute',
                        subtitle: 'Choose your role',
                      ),

                      const SizedBox(height: 15),

                      Text(
                        canUseApp
                            ? 'Account role: $role'
                            : 'Please sign in with a valid account',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                        ),
                      ),

                      const SizedBox(height: 30),

                      if (canUseApp) ...[
                        actionTile(
                          context,
                          'User',
                          'Live map, alerts and dashboard',
                          Icons.person,
                          '/user',
                        ),

                        const SizedBox(height: 14),

                        actionTile(
                          context,
                          'Reporter',
                          'Submit and track incident reports',
                          Icons.assignment,
                          '/reporter-dashboard',
                        ),

                        const SizedBox(height: 14),

                        if (isAdmin)
                          actionTile(
                            context,
                            'Admin',
                            'Reports, management and statistics',
                            Icons.admin_panel_settings,
                            '/admin',
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            child: const ListTile(
                              leading: Icon(
                                Icons.lock_outline,
                                color: Colors.grey,
                              ),
                              title: Text('Admin'),
                              subtitle: Text(
                                'Authorized administrators only',
                              ),
                              enabled: false,
                            ),
                          ),

                        const SizedBox(height: 14),
                      ],

                      actionTile(
                        context,
                        'Emergency SOS',
                        'Emergency services and contacts',
                        Icons.sos,
                        '/sos',
                      ),

                      const SizedBox(height: 25),

                      TextButton(
                        onPressed: logout,
                        child: const Text(
                          'Logout / Back to Login',
                        ),
                      ),

                      const Text(
                        'SafeRoute - Firebase Role Verification',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Protect the Admin route against direct navigation.
class AdminRouteGuard extends StatefulWidget {
  const AdminRouteGuard({super.key});

  @override
  State<AdminRouteGuard> createState() =>
      _AdminRouteGuardState();
}

class _AdminRouteGuardState
    extends State<AdminRouteGuard> {
  late final Future<String?> roleFuture;

  @override
  void initState() {
    super.initState();
    roleFuture = getCurrentUserRole();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isAdmin =
            !snapshot.hasError &&
            FirebaseAuth.instance.currentUser != null &&
            snapshot.data == 'Admin';

        if (isAdmin) {
          return const AdminScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Access Denied'),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: Colors.redAccent,
                    size: 65,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Admin access required',
                    style: TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This account does not have '
                    'administrator permission.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () =>
                        replace(context, '/roles'),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}