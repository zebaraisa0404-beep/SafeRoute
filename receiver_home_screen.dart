import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/common.dart';

class ReceiverHomeScreen extends StatefulWidget {
  const ReceiverHomeScreen({super.key});

  @override
  State<ReceiverHomeScreen> createState() =>
      _ReceiverHomeScreenState();
}

class _ReceiverHomeScreenState
    extends State<ReceiverHomeScreen> {
  late final Future<String?> roleFuture;

  @override
  void initState() {
    super.initState();
    roleFuture = loadRole();
  }

  Future<String?> loadRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;

    return doc.data()?['role'] as String?;
  }

  bool isPending(String status) {
    return status == 'Reported' ||
        status == 'Pending';
  }

  bool isActive(String status) {
    return [
      'Acknowledged',
      'Assigned',
      'Responder Assigned',
      'In Progress',
      'On the Way',
      'Arrived',
    ].contains(status);
  }

  Widget statCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget accessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 65,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 15),

            const Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Only authorized Admin or Responder '
              'accounts can access this panel.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () =>
                  replace(context, '/roles'),
              child: const Text('Back to Roles'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),

      appBar: AppBar(
        title: const Text('Receiver Panel'),
        backgroundColor: pale,
      ),

      body: FutureBuilder<String?>(
        future: roleFuture,
        builder: (context, roleSnapshot) {
          if (roleSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (roleSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to verify your role: '
                  '${roleSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final user = FirebaseAuth.instance.currentUser;
          final role = roleSnapshot.data;

          final isAdmin =
              user != null && role == 'Admin';

          final isResponder =
              user != null && role == 'Responder';

          if (!isAdmin && !isResponder) {
            return accessDenied();
          }

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('incidents')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Unable to load reports: '
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final reports = snapshot.data!.docs;

              final pending = reports.where((doc) {
                final status =
                    doc.data()['status'] as String? ??
                    'Reported';
                return isPending(status);
              }).length;

              final active = reports.where((doc) {
                final status =
                    doc.data()['status'] as String? ??
                    'Reported';
                return isActive(status);
              }).length;

              final resolved = reports.where((doc) {
                return doc.data()['status'] == 'Resolved';
              }).length;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide =
                      constraints.maxWidth >= 700;

                  return ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      const SizedBox(height: 10),

                      screenTitle(
                        'Receiver Home',
                        subtitle:
                            'Manage community incidents',
                      ),

                      const SizedBox(height: 12),

                      Center(
                        child: Text(
                          'Account role: $role',
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      sectionTitle(
                        'Incident Overview',
                      ),

                      const SizedBox(height: 12),

                      GridView.count(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        crossAxisCount: wide ? 4 : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: wide ? 3.0 : 2.0,
                        children: [
                          statCard(
                            'Total Reports',
                            reports.length,
                            Icons.assignment,
                            Colors.blue,
                          ),

                          statCard(
                            'Pending',
                            pending,
                            Icons.pending_actions,
                            Colors.orange,
                          ),

                          statCard(
                            'Active Responses',
                            active,
                            Icons.timelapse,
                            Colors.purple,
                          ),

                          statCard(
                            'Resolved',
                            resolved,
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      sectionTitle('Quick Actions'),

                      const SizedBox(height: 12),

                      actionTile(
                        context,
                        'Show Reports',
                        'View community incident reports',
                        Icons.assignment,
                        '/receiver-reports',
                      ),

                      const SizedBox(height: 14),

                      if (isAdmin) ...[
                        actionTile(
                          context,
                          'Admin Dashboard',
                          'Incident statistics and management',
                          Icons.admin_panel_settings,
                          '/admin',
                        ),

                        const SizedBox(height: 14),
                      ],

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.sync,
                              color: blue,
                            ),

                            SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                'Incident statistics are '
                                'updated in real time '
                                'from Firebase Firestore.',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      primaryButton(
                        'Back to Role Selection',
                        () => replace(
                          context,
                          '/roles',
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}