/// Driver entrypoint for Flutter Driver testing
/// This file enables automated UI testing capabilities

import 'package:flutter_driver/driver_extension.dart';
import 'main.dart' as app;

void main() {
  // Enable Flutter Driver extension for automation testing
  enableFlutterDriverExtension();

  // Run the main app
  app.main();
}
