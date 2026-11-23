import 'package:flutter/foundation.dart';

import 'models/incident.dart';

class AppStore extends ChangeNotifier {
  String currentUser = 'Raisa';

  final List<Incident> incidents = [
    Incident(
      id: 1,
      title: 'Road Accident',
      category: 'Accident',
      description: 'Demo accident report',
      severity: 'High',
      location: 'Mirpur Road, Dhaka',
      reporter: 'Demo User',
      status: 'In Progress',
      date: DateTime.now(),
    ),
    Incident(
      id: 2,
      title: 'Street Light Issue',
      category: 'Infrastructure',
      description: 'Street light not working',
      severity: 'Low',
      location: 'Block C, Mirpur',
      reporter: 'Demo User',
      date: DateTime.now(),
    ),
  ];

  void setName(String name) {
    currentUser = name;
    notifyListeners();
  }

  void add({
    required String category,
    required String severity,
    required String description,
    required String location,
    double? latitude,
    double? longitude,
  }) {
    final newIncident = Incident(
      id: DateTime.now().microsecondsSinceEpoch,
      title: '$category Report',
      category: category,
      description: description,
      severity: severity,
      location: location,
      latitude: latitude,
      longitude: longitude,
      reporter: currentUser,
      date: DateTime.now(),
    );

    incidents.insert(0, newIncident);
    notifyListeners();
  }

  void updateStatus(int id, String status) {
    final index = incidents.indexWhere((incident) => incident.id == id);

    if (index != -1) {
      incidents[index].status = status;
      notifyListeners();
    }
  }

  int count(String status) {
    return incidents.where((incident) => incident.status == status).length;
  }
}
