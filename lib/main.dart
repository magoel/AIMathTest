import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'config/app_config.dart';
import 'app.dart';

void main() async {
  // Must be called before ensureInitialized to take effect
  setUrlStrategy(PathUrlStrategy());

  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.useFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const ProviderScope(child: AIMathTestApp()));
}
