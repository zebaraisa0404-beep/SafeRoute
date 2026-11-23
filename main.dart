import 'package:material_ui/material_ui.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app_state.dart';

// SafeRoute Screens
import 'Screens/splash_screen.dart';
import 'Screens/login_screen.dart';
import 'Screens/register_screen.dart';
import 'Screens/role_screen.dart';
import 'Screens/user_home_screen.dart';
import 'Screens/report_screen.dart';
import 'Screens/map_screen.dart';
import 'Screens/directions_screen.dart';
import 'Screens/user_dashboard_screen.dart';
import 'Screens/sos_screen.dart';
import 'Screens/receiver_home_screen.dart';
import 'Screens/receiver_reports_screen.dart';
import 'Screens/reporter_dashboard_screen.dart';

// Global App Store
final appStore = AppStore();

// Initialize Firebase before starting SafeRoute.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SafeRouteApp());
}

// Main SafeRoute Application
class SafeRouteApp extends StatelessWidget {
  const SafeRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeRoute',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F9FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1268D5),
        ),
      ),

      initialRoute: '/',

      routes: {
        // Splash Screen
        '/': (context) => const SplashScreen(),

        // Authentication
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        // Firebase Role Selection
        '/roles': (context) => const RoleScreen(),

        // User Features
        '/user': (context) => const UserHomeScreen(),
        '/report': (context) => const ReportScreen(),
        '/map': (context) => const MapScreen(),
        '/directions': (context) => const DirectionsScreen(),
        '/dashboard': (context) =>
            const UserDashboardScreen(),

        // Emergency SOS
        '/sos': (context) => const SosScreen(),

        // Responder Features
        '/receiver': (context) =>
            const ReceiverHomeScreen(),

        '/receiver-reports': (context) =>
            const ReceiverReportsScreen(),

        // Protected Admin Dashboard
        '/admin': (context) =>
            const AdminRouteGuard(),

        // Reporter Dashboard
        '/reporter-dashboard': (context) =>
            const ReporterDashboardScreen(),
      },
    );
  }
}