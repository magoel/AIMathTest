import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'config/app_config.dart';
import 'app.dart';
import 'url_strategy_stub.dart' if (dart.library.html) 'url_strategy_web.dart';

void main() async {
  configureUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.useFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const ProviderScope(child: AIMathTestApp()));
}
