import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/quran_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final provider = QuranProvider();
  await provider.loadTheme();

  runApp(QuranApp(provider: provider));
}

class QuranApp extends StatelessWidget {
  final QuranProvider provider;
  const QuranApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<QuranProvider>(
        builder: (_, prov, _) => MaterialApp(
          title: 'القرآن الكريم',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: prov.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
