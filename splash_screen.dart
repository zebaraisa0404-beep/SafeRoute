import 'package:material_ui/material_ui.dart';

import '../widgets/common.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pale,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 25),

                      const Icon(Icons.shield_rounded, size: 90, color: blue),

                      const SizedBox(height: 20),

                      const Text(
                        'SafeRoute',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Your Safety, Our Priority',
                        style: TextStyle(fontSize: 18),
                      ),

                      const SizedBox(height: 45),

                      const Icon(
                        Icons.health_and_safety_rounded,
                        size: 110,
                        color: blue,
                      ),

                      const SizedBox(height: 45),

                      primaryButton(
                        'Get Started',
                        () => replace(context, '/login'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
