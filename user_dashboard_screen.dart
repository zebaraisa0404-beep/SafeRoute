import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/common.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState
    extends State<UserDashboardScreen> {
  String filter = 'All';

  final List<String> filters = [
    'All',
    'Pending',
    'In Progress',
    'Resolved',
  ];

  final List<String> progressStatuses = [
    'Acknowledged',
    'Assigned',
    'Responder Assigned',
    'In Progress',
    'On the Way',
    'Arrived',
  ];

  String statusGroup(String status) {
    if (status == 'Reported' || status == 'Pending') {
      return 'Pending';
    }

    if (status == 'Resolved') {
      return 'Resolved';
    }

    if (progressStatuses.contains(status)) {
      return 'In Progress';
    }

    return 'Other';
  }

  Color statusColor(String status) {
    switch (statusGroup(status)) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.purple;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  IconData categoryIcon(String category) {
    switch (category) {
      case 'Accident':
        return Icons.car_crash;
      case 'Fire':
        return Icons.local_fire_department;
      case 'Medical':
        return Icons.medical_services;
      case 'Security':
        return Icons.security;
      case 'Flood':
        return Icons.water;
      case 'Infrastructure':
        return Icons.construction;
      default:
        return Icons.report_problem;
    }
  }

  String formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Processing...';
    }

    final date = value.toDate().toLocal();

    String two(int number) =>
        number.toString().padLeft(2, '0');

    return '${two(date.day)}/${two(date.month)}/'
        '${date.year}  '
        '${two(date.hour)}:${two(date.minute)}';
  }

  void showReportDetails(
    BuildContext context,
    String reportId,
    Map<String, dynamic> data,
  ) {
    final category =
        data['category'] as String? ?? 'Incident';

    final description =
        data['description'] as String? ?? '';

    final location =
        data['location'] as String? ?? 'Unknown';

    final severity =
        data['severity'] as String? ?? 'Unknown';

    final status =
        data['status'] as String? ?? 'Reported';

    final latitude = data['latitude'];
    final longitude = data['longitude'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              10,
              24,
              MediaQuery.of(sheetContext)
                      .viewInsets
                      .bottom +
                  24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      categoryIcon(category),
                      color: blue,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text('Location: $location'),
                const SizedBox(height: 8),

                Text('Severity: $severity'),
                const SizedBox(height: 8),

                Text(
                  'Status: $status',
                  style: TextStyle(
                    color: statusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Submitted: '
                  '${formatDate(data['createdAt'])}',
                ),

                if (latitude is num &&
                    longitude is num) ...[
                  const SizedBox(height: 8),
                  Text(
                    'GPS: '
                    '${latitude.toStringAsFixed(6)}, '
                    '${longitude.toStringAsFixed(6)}',
                  ),
                ],

                const Divider(height: 30),

                const Text(
                  'Incident Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  description.isEmpty
                      ? 'No description available.'
                      : description,
                ),

                const SizedBox(height: 20),

                Text(
                  'Report ID: $reportId',
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Community-submitted reports are '
                  'not independently verified '
                  'emergency alerts.',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 22),

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
  }

  Widget reportCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> report,
  ) {
    final data = report.data();

    final category =
        data['category'] as String? ?? 'Incident';

    final location =
        data['location'] as String? ?? 'Unknown';

    final severity =
        data['severity'] as String? ?? 'Unknown';

    final status =
        data['status'] as String? ?? 'Reported';

    final color = statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blueGrey.withValues(alpha: 0.12),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),

        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            categoryIcon(category),
            color: blue,
            size: 25,
          ),
        ),

        title: Text(
          category,
          style: const TextStyle(
            fontSize: 15,
            color: navy,
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(location),
              const SizedBox(height: 4),
              Text('Severity: $severity'),
              const SizedBox(height: 4),
              Text(
                formatDate(data['createdAt']),
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Icon(
              Icons.chevron_right,
              size: 19,
            ),
          ],
        ),

        onTap: () {
          showReportDetails(
            context,
            report.id,
            data,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),

      appBar: AppBar(
        title: const Text('My Report History'),
        backgroundColor: pale,
      ),

      bottomNavigationBar: navBar(context, 3),

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
                  const SizedBox(height: 12),
                  const Text(
                    'Please login to view your reports.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        replace(context, '/login'),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            )
          : StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('incidents')
                  .where(
                    'userId',
                    isEqualTo: user.uid,
                  )
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Unable to load reports:\n'
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

                final allMyReports =
                    snapshot.data!.docs.toList();

                // Sort newest first without requiring
                // a composite Firestore index.
                allMyReports.sort((a, b) {
                  final aTime =
                      a.data()['createdAt'] as Timestamp?;

                  final bTime =
                      b.data()['createdAt'] as Timestamp?;

                  if (aTime == null &&
                      bTime == null) {
                    return 0;
                  }

                  if (aTime == null) return 1;
                  if (bTime == null) return -1;

                  return bTime.compareTo(aTime);
                });

                final reports = allMyReports.where((doc) {
                  final status =
                      doc.data()['status'] as String? ??
                      'Reported';

                  return filter == 'All' ||
                      statusGroup(status) == filter;
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    screenTitle(
                      'My Incident Reports',
                      subtitle:
                          'Track your submitted reports',
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Total reports: ${allMyReports.length}',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final value in filters)
                          ChoiceChip(
                            label: Text(value),
                            selected: filter == value,
                            onSelected: (_) {
                              setState(() {
                                filter = value;
                              });
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    if (reports.isEmpty)
                      panel(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.inbox_outlined,
                              color: blue,
                              size: 42,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              filter == 'All'
                                  ? 'No reports submitted yet.'
                                  : 'No $filter reports found.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                    for (final report in reports)
                      reportCard(context, report),

                    const SizedBox(height: 20),

                    primaryButton(
                      'Report Another Problem',
                      () => go(context, '/report'),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Report status is loaded in real time '
                      'from Firebase Cloud Firestore.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 15),
                  ],
                );
              },
            ),
    );
  }
}