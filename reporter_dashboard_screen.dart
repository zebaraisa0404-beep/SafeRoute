import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import '../widgets/common.dart';

class ReporterDashboardScreen extends StatelessWidget {
  const ReporterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: pale,
        title: const Text('Reporter Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Role Selection',
            onPressed: () => replace(context, '/roles'),
          ),
        ],
      ),

      body: user == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 55,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Please login to view your reports.',
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
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Unable to load reports: ${snapshot.error}',
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

                final myReports = snapshot.data!.docs.toList();

                // Newest reports first.
                myReports.sort((a, b) {
                  final aDate =
                      a.data()['createdAt'] as Timestamp?;
                  final bDate =
                      b.data()['createdAt'] as Timestamp?;

                  if (aDate == null && bDate == null) {
                    return 0;
                  }
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;

                  return bDate.compareTo(aDate);
                });

                final pending = myReports.where((doc) {
                  final status =
                      doc.data()['status'] as String? ?? '';
                  return status == 'Pending' ||
                      status == 'Reported';
                }).length;

                final progress = myReports.where((doc) {
                  final status =
                      doc.data()['status'] as String? ?? '';

                  return [
                    'In Progress',
                    'Acknowledged',
                    'Assigned',
                    'Responder Assigned',
                    'On the Way',
                    'Arrived',
                  ].contains(status);
                }).length;

                final resolved = myReports.where((doc) {
                  return doc.data()['status'] == 'Resolved';
                }).length;

                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const SizedBox(height: 10),

                    Text(
                      'Hello, ${appStore.currentUser}!',
                      style: const TextStyle(
                        fontSize: 25,
                        color: navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Manage your submitted incident reports',
                      style: TextStyle(
                        color: Colors.blueGrey,
                      ),
                    ),

                    const SizedBox(height: 25),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        statCard(
                          'My Reports',
                          myReports.length,
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
                          'In Progress',
                          progress,
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

                    const SizedBox(height: 25),

                    primaryButton(
                      'Report New Incident',
                      () => go(context, '/report'),
                    ),

                    const SizedBox(height: 15),

                    OutlinedButton.icon(
                      onPressed: () => go(context, '/map'),
                      icon: const Icon(Icons.map),
                      label: const Text('View Live Map'),
                    ),

                    const SizedBox(height: 20),

                    sectionTitle('My Submitted Reports'),

                    if (myReports.isEmpty)
                      panel(
                        child: const Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              color: blue,
                              size: 45,
                            ),
                            SizedBox(height: 10),
                            Text('No reports submitted yet'),
                            SizedBox(height: 5),
                            Text(
                              'Submit your first incident report',
                              style: TextStyle(
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),

                    for (final report in myReports)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 12),
                        child: reportCard(context, report),
                      ),

                    const SizedBox(height: 20),

                    const Text(
                      'Reports are loaded in real time '
                      'from Firebase Cloud Firestore.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget statCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget reportCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> report,
  ) {
    final data = report.data();

    final category =
        data['category'] as String? ?? 'Incident';
    final severity =
        data['severity'] as String? ?? 'Unknown';
    final status =
        data['status'] as String? ?? 'Reported';
    final location =
        data['location'] as String? ?? 'Unknown location';
    final description =
        data['description'] as String? ?? '';

    final title = '$category - $location';

    return panel(
      child: ListTile(
        leading: const Icon(
          Icons.report_problem,
          color: Colors.orange,
          size: 30,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$location\n'
          'Severity: $severity\n'
          'Status: $status',
        ),
        isThreeLine: true,
        trailing: const Icon(
          Icons.info_outline,
          color: blue,
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
                      Text(
                        'Report ID: ${report.id}',
                        style: const TextStyle(
                          fontSize: 11,
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