import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
Future<String> downloadImageToTemporaryDirectory(String imageUrl) async {
  final response = await http.get(Uri.parse(imageUrl));
   var bytes = response.bodyBytes;
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/image.png');
  await file.writeAsBytes(bytes);
  return file.path;
}