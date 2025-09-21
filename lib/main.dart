import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/di/injection_container.dart' as di;
import 'core/themes/app_theme.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/blocs/app/app_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize dependency injection
  await di.init();
  
  runApp(const ApoBasiApp());
}

class ApoBasiApp extends StatelessWidget {
  const ApoBasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<AppBloc>(),
      child: MaterialApp(
        title: 'Apo Basi - Bus Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}