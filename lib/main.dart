import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'api/permissions.dart';
import 'package:provider/provider.dart';
import 'notifiers/theme_notifier.dart';
import 'screens/auth/auth_wrapper.dart';
import 'utils/app_themes.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp();
  //await channel.invokeMethod<bool>('TriggerSnapshot');

  // final Map<String, String> m = {"number":"+911098765431"};
  // print((await channel.invokeMethod('CheckBlocked',m)) ?? false);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the theme notifier to the entire app
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'Secure App',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}