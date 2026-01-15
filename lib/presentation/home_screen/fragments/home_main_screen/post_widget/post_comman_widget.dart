import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

String parseHtmlString(String htmlString) {
  // Parse the HTML string
  dom.Document document = html_parser.parse(htmlString);

  // Extract and return the text content without tags
  return document.body?.text ?? '';
}

bool isHtml(String text) {
  // Simple regex to check if the string contains HTML tags
  final htmlTagPattern = RegExp(r'<[^>]*>');
  return htmlTagPattern.hasMatch(text);
}

String removeHtmlTags(String htmlString) {
  final RegExp htmlTagRegExp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
  return htmlString.replaceAll(htmlTagRegExp, '');
}

Color contrastingTextColor(Color bgColor) {
  // Calculate the luminance of the background color
  double luminance = bgColor.computeLuminance();
  // Return black or white text color based on luminance
  return luminance > 0.5 ? Colors.black : Colors.white;
}
