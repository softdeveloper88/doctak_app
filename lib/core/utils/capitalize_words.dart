import 'package:doctak_app/core/utils/display_identity.dart';

/// Backward-compatible export — prefer [formatDisplayName].
String capitalizeWords(String text) => formatDisplayName(text, text);
