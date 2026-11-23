import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/common.dart';

class DirectionsScreen extends StatelessWidget {
  const DirectionsScreen({super.key});

  Future<void> openGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/'
      '?api=1&destination=Mirpur%20Road%2C%20Dhaka',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Directions')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            screenTitle(
              'Route Options',
              subtitle: 'View navigation directions',
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: pale,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.alt_route, size: 140, color: blue),
              ),
            ),
            const SizedBox(height: 20),
            panel(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example Destination: Mirpur Road, Dhaka',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Google Maps will provide normal directions. '
                    'This app does not yet calculate a verified safe route.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            primaryButton('Open Google Maps', openGoogleMaps),
          ],
        ),
      ),
    );
  }
}
