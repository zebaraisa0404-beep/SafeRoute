import 'package:flutter/material.dart';

import '../widgets/common.dart';
import '../main.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Dashboard')),
      bottomNavigationBar: navBar(context, 3),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          screenTitle('My Incident Reports'),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              for (final value in ['All', 'Pending', 'In Progress', 'Resolved'])
                ChoiceChip(
                  label: Text(value),
                  selected: filter == value,
                  onSelected: (_) {
                    setState(() => filter = value);
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: appStore,
            builder: (context, _) {
              final reports = appStore.incidents.where(
                (incident) => filter == 'All' || incident.status == filter,
              );

              return Column(
                children: [
                  for (final incident in reports)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: incidentTile(context, incident),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 25),
          primaryButton('Report Another Problem', () => go(context, '/report')),
        ],
      ),
    );
  }
}
