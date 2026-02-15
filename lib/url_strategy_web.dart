import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Use path-based URLs on web (no hash fragment).
void configureUrlStrategy() {
  setUrlStrategy(PathUrlStrategy());
}
