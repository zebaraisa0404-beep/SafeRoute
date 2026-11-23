import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/common.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String selectedFilter = 'All';

  static const filters = ['All', 'Pending', 'In Progress', 'Resolved'];
  static const statuses = [
    'Reported',
    'Acknowledged',
    'Responder Assigned',
    'On the Way',
    'Arrived',
    'Resolved',
  ];
  static const categories = [
    'Accident', 'Fire', 'Medical', 'Security', 'Flood', 'Infrastructure',
  ];

  String statusGroup(String status) {
    if (status == 'Reported' || status == 'Pending') return 'Pending';
    if (status == 'Resolved') return 'Resolved';
    if (['Acknowledged', 'Assigned', 'Responder Assigned', 'On the Way',
      'Arrived', 'In Progress'].contains(status)) {
      return 'In Progress';
    }
    return 'Other';
  }

  String formatDate(dynamic raw) {
    if (raw is! Timestamp) return 'Processing...';
    final date = raw.toDate().toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  void message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Widget statCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            child: Icon(icon, size: 23, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$value', style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.bold, color: navy,
                )),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showReportDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> report,
  ) async {
    final data = report.data();
    final oldStatus = data['status'] as String? ?? 'Reported';
    String chosenStatus = statuses.contains(oldStatus) ? oldStatus : 'Reported';
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20, 8, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${data['category'] ?? 'Incident'}',
                  style: const TextStyle(fontSize: 23, color: navy,
                    fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Report ID: ${report.id}',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                Text('Severity: ${data['severity'] ?? 'Unknown'}'),
                Text('Location: ${data['location'] ?? 'Unknown'}'),
                Text('Reported: ${formatDate(data['createdAt'])}'),
                Text('Current status: $oldStatus'),
                const SizedBox(height: 12),
                const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${data['description'] ?? ''}'),
                const SizedBox(height: 20),
                const Text('Update Incident Status',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: chosenStatus,
                  decoration: const InputDecoration(
                    labelText: 'Select status', border: OutlineInputBorder(),
                  ),
                  items: statuses.map((value) => DropdownMenuItem(
                    value: value, child: Text(value),
                  )).toList(),
                  onChanged: saving ? null : (value) {
                    if (value != null) {
                      updateSheet(() => chosenStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (saving)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Status'),
                      onPressed: chosenStatus == oldStatus ? null : () async {
                        updateSheet(() => saving = true);
                        try {
                          // Firestore security rules must independently verify
                          // that the signed-in user is an authorized Admin.
                          await FirebaseFirestore.instance
                              .collection('incidents')
                              .doc(report.id)
                              .update({'status': chosenStatus});
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                          message('Status updated to $chosenStatus');
                        } on FirebaseException catch (error) {
                          message('Status update failed: ${error.code}');
                        } catch (error) {
                          message('Could not update status: $error');
                        } finally {
                          if (sheetContext.mounted) {
                            updateSheet(() => saving = false);
                          }
                        }
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(sheetContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget adminContent() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('incidents').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Unable to load incidents: ${snapshot.error}',
              textAlign: TextAlign.center),
          ));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snapshot.data!.docs.toList();
        all.sort((a, b) {
          final x = a.data()['createdAt'] as Timestamp?;
          final y = b.data()['createdAt'] as Timestamp?;
          if (x == null && y == null) return 0;
          if (x == null) return 1;
          if (y == null) return -1;
          return y.compareTo(x);
        });

        final pending = all.where((d) =>
            statusGroup('${d.data()['status'] ?? ''}') == 'Pending').length;
        final progress = all.where((d) =>
            statusGroup('${d.data()['status'] ?? ''}') == 'In Progress').length;
        final resolved = all.where((d) =>
            statusGroup('${d.data()['status'] ?? ''}') == 'Resolved').length;
        final reports = all.where((d) => selectedFilter == 'All' ||
            statusGroup('${d.data()['status'] ?? ''}') == selectedFilter).toList();

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SizedBox(height: 8),
            const Text('Admin Overview', style: TextStyle(
              fontSize: 25, fontWeight: FontWeight.bold, color: navy,
            )),
            const SizedBox(height: 5),
            const Text('Monitor and manage community incident reports',
              style: TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 22),
            LayoutBuilder(builder: (context, size) {
              final columns = size.maxWidth >= 750 ? 4 : 2;
              const gap = 12.0;
              final cardWidth = (size.maxWidth - (columns - 1) * gap) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(width: cardWidth, height: 94,
                    child: statCard('Total Reports', all.length,
                      Icons.assignment, Colors.blue)),
                  SizedBox(width: cardWidth, height: 94,
                    child: statCard('Pending', pending,
                      Icons.pending_actions, Colors.orange)),
                  SizedBox(width: cardWidth, height: 94,
                    child: statCard('In Progress', progress,
                      Icons.timelapse, Colors.purple)),
                  SizedBox(width: cardWidth, height: 94,
                    child: statCard('Resolved', resolved,
                      Icons.check_circle, Colors.green)),
                ],
              );
            }),
            const SizedBox(height: 22),
            sectionTitle('Reports by Category'),
            panel(child: Column(children: [
              for (final category in categories)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.bar_chart, color: blue),
                  title: Text(category),
                  trailing: Text('${all.where((d) =>
                    d.data()['category'] == category).length}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ])),
            const SizedBox(height: 22),
            sectionTitle('Manage Incident Reports'),
            DropdownButtonFormField<String>(
              key: ValueKey(selectedFilter),
              initialValue: selectedFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by Status', filled: true,
                fillColor: Colors.white, border: OutlineInputBorder(),
              ),
              items: filters.map((status) => DropdownMenuItem(
                value: status, child: Text(status),
              )).toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedFilter = value);
              },
            ),
            const SizedBox(height: 12),
            Text('${reports.length} report(s) found',
              style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 12),
            if (reports.isEmpty)
              panel(child: const Text('No reports match this filter.',
                textAlign: TextAlign.center)),
            for (final report in reports)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: panel(child: ListTile(
                  leading: Icon(
                    report.data()['severity'] == 'High'
                        ? Icons.warning_rounded
                        : Icons.assignment_outlined,
                    color: report.data()['severity'] == 'High'
                        ? Colors.red : Colors.orange,
                  ),
                  title: Text('${report.data()['category'] ?? 'Incident'}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${report.data()['location'] ?? 'Unknown location'}\n'
                    'Status: ${report.data()['status'] ?? 'Reported'}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right, color: blue),
                  onTap: () => showReportDetails(report),
                )),
              ),
            const SizedBox(height: 16),
            actionTile(context, 'Receiver Reports',
              'View reports and response activity',
              Icons.support_agent, '/receiver-reports'),
            const SizedBox(height: 18),
            const Text('Live Firestore reports. Only approved Admin accounts '
              'can update statuses; community reports are unverified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: pale,
        actions: [
          IconButton(
            tooltip: 'Role Selection',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => replace(context, '/roles'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please login to access Admin Dashboard.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Role verification error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.data!.exists ||
                    snapshot.data!.data()?['role'] != 'Admin') {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Access denied. Authorized Admin only.',
                      textAlign: TextAlign.center),
                  ));
                }
                return adminContent();
              },
            ),
    );
  }
}
