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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        title: Row(
          children: [
            Icon(
              Icons.article_outlined,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Sources (${sources.length})',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        collapsedBackgroundColor: colorScheme.primary.withOpacity(0.05),
        backgroundColor: colorScheme.primary.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        children: sources.map((source) => _buildSourceItem(context, source)).toList(),
      ),
    );
  }

  Widget _buildSourceItem(BuildContext context, Source source) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      leading: Icon(
        Icons.public,
        size: 16,
        color: colorScheme.primary,
      ),
      title: Text(
        source.title ?? 'Web source',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        source.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.7),
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