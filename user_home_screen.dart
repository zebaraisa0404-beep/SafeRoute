import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/common.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

      body: AnimatedBuilder(
        animation: appStore,
        builder: (context, child) {
          final allReports = appStore.incidents;

          final myReports = allReports
              .where((report) => report.reporter == appStore.currentUser)
              .toList();

          final pending = myReports
              .where(
                (report) =>
                    report.status == 'Pending' || report.status == 'Reported',
              )
              .length;

          final inProgress = myReports
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
              const SizedBox(height: 8),

              Text(
                'Hello, ${appStore.currentUser}!',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Stay informed. Stay safe.',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey),
              ),

              const SizedBox(height: 22),

              // Dashboard welcome card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1268D5), Color(0xFF102C59)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              sectionTitle('My Report Overview'),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
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
              ),

              const SizedBox(height: 22),

              sectionTitle('Quick Actions'),

              actionTile(
                context,
                'Live Safety Map',
                'GPS, incident markers and road routes',
                Icons.map_outlined,
                '/map',
              ),

              const SizedBox(height: 12),

              actionTile(
                context,
                'Report Incident',
                'Submit a new community safety report',
                Icons.report_problem_outlined,
                '/report',
              ),

              const SizedBox(height: 12),

              actionTile(
                context,
                'My Report History',
                'Check status of submitted reports',
                Icons.history,
                '/dashboard',
              ),

              const SizedBox(height: 12),

              actionTile(
                context,
                'Emergency SOS',
                'Open emergency assistance options',
                Icons.sos,
                '/sos',
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
                    Icon(Icons.info_outline, color: Colors.deepOrange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Prototype data: These reports are '
                        'not verified emergency alerts. '
                        'Firebase live updates will be '
                        'connected later.',
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

              for (final report in allReports.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: incidentTile(context, report),
                ),

              const SizedBox(height: 20),

              primaryButton('Open Live Map', () => go(context, '/map')),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String title, int count, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              color: navy,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
