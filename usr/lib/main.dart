import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/browser_provider.dart';
import 'screens/browser_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Removed SystemChrome.setPreferredOrientations as it can cause issues on some web renderers
  // and is primarily for mobile. We can re-enable it conditionally for mobile if needed.

  runApp(const PrivacyBrowserApp());
}

class PrivacyBrowserApp extends StatelessWidget {
  const PrivacyBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BrowserProvider()),
      ],
      child: MaterialApp(
        title: 'Privacy Browser',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2C3E50),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2C3E50),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const BrowserHome(),
        },
      ),
    );
  }
}
