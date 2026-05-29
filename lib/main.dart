import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bible_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BibleProvider()),
      ],
      child: const BibalayaApp(),
    ),
  );
}

class BibalayaApp extends StatelessWidget {
  const BibalayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BibleProvider>(context);
    
    return MaterialApp(
      title: 'Bibalaya Mobile',
      debugShowCheckedModeBanner: false,
      themeMode: provider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
      ),
      home: const HomeScreen(),
    );
  }
}
