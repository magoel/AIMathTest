import 'package:flutter/foundation.dart';
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

  // Log detailed Flutter errors to browser console (works in release builds)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Use print (not debugPrint) to ensure output reaches browser console in release
    print('=== FLUTTER ERROR DETAILS ===');
    print('Exception: ${details.exception}');
    print('Exception type: ${details.exception.runtimeType}');
    print('Library: ${details.library}');
    print('Context: ${details.context}');
    print('Stack: ${details.stack}');
    if (details.informationCollector != null) {
      for (final info in details.informationCollector!()) {
        print('  INFO: $info');
      }
    }
    print('=== END ERROR DETAILS ===');
  };

  if (AppConfig.useFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const ProviderScope(child: AIMathTestApp()));
}
