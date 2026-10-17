import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/projector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape orientation (projector standard)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system navigation bar and status bar for immersive full screen
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const LumiCastApp());
}

class LumiCastApp extends StatelessWidget {
  const LumiCastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LumiCast',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2563EB),
          secondary: Color(0xFF60A5FA),
          surface: Color(0xFF161C28),
        ),
        fontFamily: 'Roboto',
      ),
      home: const ProjectorScreen(),
    );
  }
}
