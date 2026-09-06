import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/obsidian_theme.dart';
import 'core/network/pocketbase_client.dart';
import 'data/sync/pocketbase_sync_engine.dart';
import 'presentation/screens/main_navigation_shell.dart';
import 'data/database/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark OLED system overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Database Service
  await DatabaseService().init();

  // Initialize PocketBase Client and Offline-First Sync Engine
  await PocketBaseClient().initialize();
  PocketBaseSyncEngine().initialize();

  runApp(const ScreenVaultApp());
}

class ScreenVaultApp extends StatelessWidget {
  const ScreenVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Vault',
      debugShowCheckedModeBanner: false,
      theme: ObsidianTheme.darkTheme,
      home: const MainNavigationShell(),
    );
  }
}
