import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/translation_service.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => TranslationService()),
      ],
      child: const VidhanaApp(),
    ),
  );
}

class VidhanaApp extends StatelessWidget {
  const VidhanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationService>(
      builder: (_, tr, __) => MaterialApp(
        title: 'Vidhana AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
