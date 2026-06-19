import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/config/env/env.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/auth/role_selector_screen.dart';
import 'package:maucoffee/navigation/navigation.dart';
import 'package:maucoffee/home/employee_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  // Inisialisasi service locator (GetIt)
  await setUpLocator();

  // Membaca status login saat ini untuk merutekan ke screen yang sesuai secara instan
  final prefs = serviceLocator<UserPreference>();
  final String? role = prefs.getLoginRole();
  final bool hasAdminToken = prefs.getToken() != null;
  final bool hasEmployeeData = prefs.getEmployee() != null;

  Widget initialScreen;
  if (role == 'admin' && hasAdminToken) {
    initialScreen = const MainNavigation();
  } else if (role == 'employee' && hasEmployeeData) {
    initialScreen = const EmployeeHomeScreen();
  } else {
    initialScreen = const RoleSelectorScreen();
  }

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({
    super.key,
    required this.initialScreen,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mau Coffee POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE27D00),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1C1207),
      ),
      home: initialScreen,
    );
  }
}
