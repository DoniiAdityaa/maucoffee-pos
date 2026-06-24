import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/config/env/env.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maucoffee/features/cubit/absensi_cubit.dart';
import 'package:maucoffee/repository/absensi_repository.dart';
import 'package:maucoffee/auth/role_selector_screen.dart';
import 'package:maucoffee/navigation/navigation.dart';

import 'package:maucoffee/services/sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  // Inisialisasi service locator (GetIt)
  await setUpLocator();

  // Inisialisasi SyncManager untuk sinkronisasi offline
  SyncManager().initialize();

  // Membaca status login saat ini untuk merutecan ke screen yang sesuai secara instan
  final prefs = serviceLocator<UserPreference>();
  final String? role = prefs.getLoginRole();
  final bool hasAdminToken = prefs.getToken() != null;
  final bool hasEmployeeData = prefs.getEmployee() != null;

  Widget initialScreen;
  if (role == 'admin' && hasAdminToken) {
    initialScreen = const MainNavigation();
  } else if (role == 'employee' && hasEmployeeData) {
    initialScreen = const MainNavigation();
  } else {
    initialScreen = const RoleSelectorScreen();
  }

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AbsensiCubit(serviceLocator<AbsensiRepository>())
            ..fetchActiveShifts()
            ..fetchShiftHistory(),
        ),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
