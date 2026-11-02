import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'core/network/token_storage.dart';
import 'core/notifications/push_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenStorage.init();
  try {
    await initializePushFirebase();
  } catch (_) {
    debugPrint('Push Firebase initialization failed; inbox remains available.');
  }

  // Set status bar transparent and dark icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const VexGoApp());
}
