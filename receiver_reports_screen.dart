import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/common.dart';

class ReceiverReportsScreen extends StatefulWidget {
  const ReceiverReportsScreen({super.key});

  @override
  State<ReceiverReportsScreen> createState() =>
      _ReceiverReportsScreenState();
}

class _ReceiverReportsScreenState
    extends State<ReceiverReportsScreen> {
  late final Future<String?> roleFuture;

  static const List<String> statuses = [
    'Reported',
    'Pending',
    'Acknowledged',
    'Assigned',
    'Responder Assigned',
    'On the Way',
    'Arrived',
    'In Progress',
    'Resolved',
  ];

  @override
  void initState() {
    super.initState();
    roleFuture = loadRole();
  }

  Future<String?> loadRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!profile.exists) return null;

    return profile.data()?['role'] as String?;
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String formattedDate(dynamic value) {
    if (value is! Timestamp) return 'Processing...';

    final date = value.toDate().toLocal();

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Color statusColor(String status) {
    if (status == 'Resolved') return Colors.green;

    if (status == 'Reported' || status == 'Pending') {
      return Colors.orange;
    }

    return Colors.purple;
  }

  Future<void> showReport(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> report,
    bool canUpdate,
  ) async {
    final data = report.data();

    final category =
        data['category'] as String? ?? 'Incident';

    final severity =
        data['severity'] as String? ?? 'Unknown';

    final location =
        data['location'] as String? ?? 'Unknown location';

    final description =
        data['description'] as String? ?? '';

    final status =
        data['status'] as String? ?? 'Reported';

    final reporterId =
        data['userId'] as String? ?? 'Unknown';

    String selectedStatus =
        statuses.contains(status) ? status : 'Reported';

    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, updateSheet) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  12,
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
                    Text(
                      category,
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 23,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text('Category: $category'),
                    Text('Severity: $severity'),
                    Text('Location: $location'),
                    Text('Reporter UID: $reporterId'),

                    Text(
                      'Date: '
                      '${formattedDate(data['createdAt'])}',
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Current Status: $status',
                      style: TextStyle(
                        color: statusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'Incident Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(description),

                    const SizedBox(height: 22),

                    if (canUpdate) ...[
                      const Text(
                        'Update Incident Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        key: ValueKey(report.id),
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Select Status',
                          border: OutlineInputBorder(),
                        ),
                        items: statuses.map((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;

                                updateSheet(() {
                                  selectedStatus = value;
                                });
                              },
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: saving ||
                                  selectedStatus == status
                              ? null
                              : () async {
                                  updateSheet(() {
                                    saving = true;
                                  });

                                  try {
                                    await FirebaseFirestore
                                        .instance
                                        .collection('incidents')
                                        .doc(report.id)
                                        .update({
                                      'status': selectedStatus,
                                    });

                                    if (!sheetContext.mounted) {
                                      return;
                                    }

                                    Navigator.pop(sheetContext);

                                    showMessage(
                                      'Status updated to '
                                      '$selectedStatus',
                                    );
                                  } on FirebaseException catch (e) {
                                    showMessage(
                                      'Update failed: ${e.code}',
                                    );
                                  } catch (e) {
                                    showMessage(
                                      'Update failed: $e',
                                    );
                                  } finally {
                                    if (sheetContext.mounted) {
                                      updateSheet(() {
                                        saving = false;
                                      });
                                    }
                                  }
                                },
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            saving
                                ? 'Saving...'
                                : 'Save Status',
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Responder view only. '
                          'Status updates currently require '
                          'an authorized Admin account.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: saving
                            ? null
                            : () => Navigator.pop(
                                  sheetContext,
                                ),
                        child: const Text('Close'),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget reportTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> report,
    bool canUpdate,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: panel(
        child: ListTile(
          leading: Icon(
            severity == 'High'
                ? Icons.warning_rounded
                : Icons.assignment_outlined,
            color: severity == 'High'
                ? Colors.red
                : Colors.orange,
            size: 28,
          ),

          title: Text(
            category,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),

          subtitle: Text(
            '$location\n'
            'Severity: $severity\n'
            'Status: $status',
          ),

          isThreeLine: true,

          trailing: const Icon(
            Icons.chevron_right,
            color: blue,
          ),

          onTap: () {
            showReport(
              context,
              report,
              canUpdate,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text('Receiver Reports'),
        backgroundColor: pale,
        actions: [
          IconButton(
            tooltip: 'Role Selection',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => replace(context, '/roles'),
          ),
        ],
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
              child: Text(
                'Unable to verify role: '
                '${roleSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final role = roleSnapshot.data;

          final signedIn =
              FirebaseAuth.instance.currentUser != null;

          final isAdmin = signedIn && role == 'Admin';

          final isResponder =
              signedIn && role == 'Responder';

          if (!isAdmin && !isResponder) {
            return Center(
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
                    const SizedBox(height: 15),
                    const Text(
                      'Access Denied',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Only authorized Admin or '
                      'Responder accounts can '
                      'access Receiver Reports.',
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
            );
          }

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('incidents')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Unable to load reports:\n'
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final reports =
                  snapshot.data!.docs.toList();

              reports.sort((a, b) {
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

              final pending = reports.where((report) {
                final status =
                    report.data()['status'];

                return status == 'Reported' ||
                    status == 'Pending';
              }).length;

              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  screenTitle(
                    'Submitted Reports',
                    subtitle:
                        'Monitor community incidents '
                        'and their response status',
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.assignment,
                          color: blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${reports.length} total reports'
                            '  •  $pending pending',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (reports.isEmpty)
                    panel(
                      child: const Center(
                        child: Text(
                          'No incident reports available.',
                        ),
                      ),
                    ),

                  for (final report in reports)
                    reportTile(
                      context,
                      report,
                      isAdmin,
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

                  const SizedBox(height: 18),
                ],
              );
            },
          );
        },
      ),
    );
  }
}