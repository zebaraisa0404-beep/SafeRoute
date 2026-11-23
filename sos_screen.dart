import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/common.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  Future<void> dialNumber(String number) async {
    final url = Uri(scheme: 'tel', path: number);

    await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFECEC),
      appBar: AppBar(title: const Text('Emergency SOS')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.sos, size: 100, color: Colors.red),
          const SizedBox(height: 20),
          screenTitle(
            'Emergency Assistance',
            subtitle: 'Choose an emergency service',
          ),
          const SizedBox(height: 20),
          panel(
            child: const Text(
              'Academic prototype only. This app does not '
              'automatically contact or dispatch responders.',
              style: TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 25),
          serviceButton('Police', Icons.local_police, () => dialNumber('999')),
          serviceButton(
            'Fire Service',
            Icons.local_fire_department,
            () => dialNumber('999'),
          ),
          serviceButton(
            'Ambulance',
            Icons.medical_services,
            () => dialNumber('999'),
          ),
          const SizedBox(height: 25),
          primaryButton('Back to Home', () => replace(context, '/roles')),
        ],
      ),
    );
  }

  Widget serviceButton(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: panel(
        child: ListTile(
          leading: Icon(icon, color: Colors.red, size: 30),
          title: Text(title),
          subtitle: const Text('Bangladesh national emergency: 999'),
          trailing: const Icon(Icons.call),
          onTap: onTap,
        ),
      ),
    );
  }
}
