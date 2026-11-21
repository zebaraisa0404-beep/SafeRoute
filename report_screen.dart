import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/common.dart';
import '../main.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String category = 'Accident';
  String severity = 'Medium';

  final description = TextEditingController();
  final location = TextEditingController();

  double? latitude;
  double? longitude;

  bool locating = false;

  String locationMessage = 'GPS coordinates not selected yet.';

  @override
  void dispose() {
    description.dispose();
    location.dispose();
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    if (locating) return;

    setState(() {
      locating = true;
      locationMessage = 'Getting GPS location...';
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw Exception('Device location is disabled.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Please allow location access in Chrome.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;

        locationMessage = 'GPS location selected!';

        if (location.text.trim().isEmpty) {
          location.text = 'Current GPS Location';
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        latitude = null;
        longitude = null;
        locationMessage = 'Location error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          locating = false;
        });
      }
    }
  }

  void submitReport() {
    if (description.text.trim().isEmpty || location.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter description and location.')),
      );
      return;
    }

    appStore.add(
      category: category,
      severity: severity,
      description: description.text.trim(),
      location: location.text.trim(),
      latitude: latitude,
      longitude: longitude,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo report submitted successfully!')),
    );

    // Reporter dashboard includes submitted reports.
    replace(context, '/reporter-dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        backgroundColor: pale,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          screenTitle('Report Problem', subtitle: 'Tell us what happened'),

          sectionTitle('Incident Category'),

          Wrap(
            spacing: 8,
            children: [
              for (final item in [
                'Accident',
                'Fire',
                'Medical',
                'Security',
                'Flood',
                'Infrastructure',
              ])
                ChoiceChip(
                  label: Text(item),
                  selected: category == item,
                  onSelected: (_) {
                    setState(() {
                      category = item;
                    });
                  },
                ),
            ],
          ),

          sectionTitle('Severity'),

          Wrap(
            spacing: 8,
            children: [
              for (final item in ['Low', 'Medium', 'High'])
                ChoiceChip(
                  label: Text(item),
                  selected: severity == item,
                  onSelected: (_) {
                    setState(() {
                      severity = item;
                    });
                  },
                ),
            ],
          ),

          const SizedBox(height: 20),

          entry('Incident Description', description, lines: 4),

          const SizedBox(height: 12),

          entry('Incident Location Name', location),

          const SizedBox(height: 18),

          sectionTitle('GPS Location'),

          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attach GPS Coordinates',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  const SizedBox(height: 8),

                  Text(locationMessage, style: const TextStyle(fontSize: 13)),

                  const SizedBox(height: 12),

                  if (latitude != null && longitude != null) ...[
                    Text(
                      'Latitude: '
                      '${latitude!.toStringAsFixed(6)}',
                    ),
                    Text(
                      'Longitude: '
                      '${longitude!.toStringAsFixed(6)}',
                    ),
                    const SizedBox(height: 12),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: locating ? null : getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(
                        locating
                            ? 'Getting Location...'
                            : 'Use My Current GPS Location',
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Use GPS only if you are at the '
                    'incident location. Otherwise enter '
                    'the incident location name without '
                    'attaching your current coordinates.',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          panel(
            child: const ListTile(
              leading: Icon(Icons.add_a_photo, color: blue),
              title: Text('Add Photo'),
              subtitle: Text(
                'Photo selection and upload '
                'will be added later.',
              ),
            ),
          ),

          const SizedBox(height: 25),

          primaryButton('Submit Report', submitReport),

          const SizedBox(height: 12),

          const Text(
            'Prototype: Report is saved locally '
            'in app memory. Firebase database '
            'integration is not connected yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
