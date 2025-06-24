import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/ai_chat_model/ai_chat_message_model.dart';

class SourceCitationWidget extends StatelessWidget {
  final List<Source> sources;

  const SourceCitationWidget({
    Key? key,
    required this.sources,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        title: Row(
          children: [
            Icon(
              Icons.article_outlined,
              size: 16,
              color: Colors.blue[600],
            ),
            const SizedBox(width: 8),
            Text(
              'Sources (${sources.length})',
              style: TextStyle(
                color: Colors.blue[600],
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ],
        ),
        collapsedBackgroundColor: Colors.blue.withOpacity(0.05),
        backgroundColor: Colors.blue.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.blue.withOpacity(0.1),
            width: 1,
          ),
        ),
        children: sources.map((source) => _buildSourceItem(context, source)).toList(),
      ),
    );
  }

  Widget _buildSourceItem(BuildContext context, Source source) {

    return ListTile(
      dense: true,
      leading: Icon(
        Icons.public,
        size: 16,
        color: Colors.blue[600],
      ),
      title: Text(
        source.title ?? 'Web source',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        source.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'Poppins',
          color: Colors.grey[600],
        ),
      ),
      onTap: () async {
        try {
          await launchUrl(Uri.parse(source.url));
        } catch (e) {
          print('Could not launch URL: ${source.url}');
        }
      },
    );
  }
}