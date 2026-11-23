import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import '../widgets/common.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text('User Dashboard'),
        backgroundColor: pale,
        actions: [
          IconButton(
            tooltip: 'Role Selection',
            icon: const Icon(Icons.switch_account),
            onPressed: () => replace(context, '/roles'),
          ),
        ],
      ),

      bottomNavigationBar: navBar(context, 0),

      body: user == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 50,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please login to view your dashboard.',
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () =>
                        replace(context, '/login'),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('incidents')
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Unable to load incidents: '
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

                // Load real incidents from Firestore.
                final allReports = snapshot.data!.docs.toList();

                // Show newest incidents first.
                allReports.sort((a, b) {
                  final aTime =
                      a.data()['createdAt'] as Timestamp?;
                  final bTime =
                      b.data()['createdAt'] as Timestamp?;

                  if (aTime == null && bTime == null) {
                    return 0;
                  }

                  if (aTime == null) return 1;
                  if (bTime == null) return -1;

                  return bTime.compareTo(aTime);
                });

                // Match reports using Firebase UID.
                final myReports = allReports.where((report) {
                  return report.data()['userId'] == user.uid;
                }).toList();

                final pending = myReports.where((report) {
                  final status = report.data()['status'];

                  return status == 'Pending' ||
                      status == 'Reported';
                }).length;

                final inProgress = myReports.where((report) {
                  final status = report.data()['status'];

                  return [
                    'In Progress',
                    'Acknowledged',
                    'Assigned',
                    'Responder Assigned',
                    'On the Way',
                    'Arrived',
                  ].contains(status);
                }).length;

                final resolved = myReports.where((report) {
                  return report.data()['status'] == 'Resolved';
                }).length;

                final displayName =
                    user.displayName?.trim().isNotEmpty == true
                        ? user.displayName!
                        : appStore.currentUser;

                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const SizedBox(height: 8),

                    Text(
                      'Hello, $displayName!',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Stay informed. Stay safe.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Community Safety welcome banner.
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1268D5),
                            Color(0xFF102C59),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            size: 38,
                            color: Colors.white,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Community Safety',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'View incident reports, access the '
                            'live map, and find available routes.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    sectionTitle('My Report Overview'),

                    // Compact cards: 4 across on desktop, 2 on mobile.
                    // Fixed height prevents oversized dashboard blocks.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount:
                              constraints.maxWidth >= 850 ? 4 : 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 94,
                          children: [
                        _statCard(
                          'My Reports',
                          myReports.length,
                          Icons.assignment,
                          Colors.blue,
                        ),
                        _statCard(
                          'Pending',
                          pending,
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                        _statCard(
                          'In Progress',
                          inProgress,
                          Icons.timelapse,
                          Colors.purple,
                        ),
                        _statCard(
                          'Resolved',
                          resolved,
                          Icons.check_circle,
                          Colors.green,
                        ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    sectionTitle('Quick Actions'),

                    // Responsive action layout:
                    // Desktop/tablet: two columns. Phone: one column.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 12.0;
                        final twoColumns = constraints.maxWidth >= 700;
                        final tileWidth = twoColumns
                            ? (constraints.maxWidth - gap) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            SizedBox(
                              width: tileWidth,
                              child: actionTile(
                                context,
                                'Live Safety Map',
                                'GPS, incident markers and road routes',
                                Icons.map_outlined,
                                '/map',
                              ),
                            ),
                            SizedBox(
                              width: tileWidth,
                              child: actionTile(
                                context,
                                'Report Incident',
                                'Submit a new community safety report',
                                Icons.report_problem_outlined,
                                '/report',
                              ),
                            ),
                            SizedBox(
                              width: tileWidth,
                              child: actionTile(
                                context,
                                'My Report History',
                                'Check status of submitted reports',
                                Icons.history,
                                '/dashboard',
                              ),
                            ),
                            SizedBox(
                              width: tileWidth,
                              child: actionTile(
                                context,
                                'Emergency SOS',
                                'Open emergency assistance options',
                                Icons.sos,
                                '/sos',
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    sectionTitle('Community Incident Reports'),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.deepOrange,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Community-submitted reports are '
                              'loaded from Firebase in real time. '
                              'Reports are not independently '
                              'verified emergency alerts.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (allReports.isEmpty)
                      panel(
                        child: const Text(
                          'No incident reports available.',
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Show the latest 3 Firestore incidents.
                    for (final report in allReports.take(3))
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 12),
                        child: _incidentTile(context, report),
                      ),

                    const SizedBox(height: 20),

                    primaryButton(
                      'Open Live Map',
                      () => go(context, '/map'),
                    ),

                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
    );
  }

  // Compact, horizontal statistics card.
  Widget _statCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Real Firestore incident list item.
  Widget _incidentTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> report,
  ) {
    final data = report.data();

    final category =
        data['category'] as String? ?? 'Incident';

    final location =
        data['location'] as String? ?? 'Unknown location';

    final severity =
        data['severity'] as String? ?? 'Unknown';

    final status =
        data['status'] as String? ?? 'Reported';

    final description =
        data['description'] as String? ?? '';

    final title = category == 'Accident'
        ? 'Road Accident'
        : category;

    return panel(
      child: ListTile(
        leading: Icon(
          category == 'Fire'
              ? Icons.local_fire_department
              : Icons.warning_amber_rounded,
          color: category == 'Fire'
              ? Colors.red
              : Colors.orange,
          size: 30,
        ),

        title: Text(title),

        subtitle: Text(
          '$location\nSeverity: $severity',
        ),

        isThreeLine: true,

        trailing: Text(
          status,
          style: const TextStyle(
            color: Colors.blueGrey,
            fontSize: 12,
          ),
        ),

        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (sheetContext) {
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text('Category: $category'),
                      Text('Severity: $severity'),
                      Text('Location: $location'),
                      Text('Status: $status'),

                      const SizedBox(height: 15),

                      const Text(
                        'Description:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(description),

                      const SizedBox(height: 15),

                      const Text(
                        'Community-submitted report. '
                        'Details have not been '
                        'independently verified.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),

                      const SizedBox(height: 20),

                      primaryButton(
                        'Close',
                        () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}