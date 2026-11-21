import 'package:flutter/material.dart';

import '../main.dart';
import '../models/incident.dart';
import '../widgets/common.dart';

class ReporterDashboardScreen extends StatelessWidget {
  const ReporterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

      body: AnimatedBuilder(
        animation: appStore,
        builder: (context, child) {
          final myReports = appStore.incidents
              .where((incident) => incident.reporter == appStore.currentUser)
              .toList();

          final pending = myReports
              .where(
                (report) =>
                    report.status == 'Pending' || report.status == 'Reported',
              )
              .length;

          final progress = myReports
              .where(
                (report) =>
                    report.status == 'In Progress' ||
                    report.status == 'Acknowledged' ||
                    report.status == 'Assigned' ||
                    report.status == 'On the Way' ||
                    report.status == 'Arrived',
              )
              .length;

          final resolved = myReports
              .where((report) => report.status == 'Resolved')
              .length;

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
                style: TextStyle(color: Colors.blueGrey),
              ),

              const SizedBox(height: 25),

              // Report statistics
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                      Icon(Icons.inbox_outlined, color: blue, size: 45),
                      SizedBox(height: 10),
                      Text('No reports submitted yet'),
                      SizedBox(height: 5),
                      Text(
                        'Submit your first incident report',
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),

              for (final report in myReports)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: reportCard(context, report),
                ),

              const SizedBox(height: 20),

              const Text(
                'Prototype: Report data is currently stored '
                'in app memory. Firebase will be integrated later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey, fontSize: 11),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget statCard(String title, int count, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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

  Widget reportCard(BuildContext context, Incident report) {
    return panel(
      child: ListTile(
        leading: const Icon(
          Icons.report_problem,
          color: Colors.orange,
          size: 30,
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${report.location}\n'
          'Severity: ${report.severity}\n'
          'Status: ${report.status}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.info_outline, color: blue),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (sheetContext) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text('Category: ${report.category}'),
                      Text('Severity: ${report.severity}'),
                      Text('Location: ${report.location}'),
                      Text('Status: ${report.status}'),
                      const SizedBox(height: 15),
                      const Text(
                        'Description:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(report.description),
                      const SizedBox(height: 20),
                      primaryButton('Close', () => Navigator.pop(sheetContext)),
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
