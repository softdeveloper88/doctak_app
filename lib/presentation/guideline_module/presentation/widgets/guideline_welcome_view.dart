import 'package:doctak_app/presentation/guideline_module/data/models/guideline_chat_model.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Welcome view shown when no messages exist — matches the reference design.
class GuidelineWelcomeView extends StatelessWidget {
  final List<GuidelineSuggestedTopic> topics;
  final Function(String query) onTopicTap;

  const GuidelineWelcomeView({
    super.key,
    required this.topics,
    required this.onTopicTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Agent Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A84FF).withOpacity(0.1),
                  const Color(0xFF5AC8FA).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.local_hospital_rounded,
                  size: 40,
                  color: Color(0xFF0A84FF),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.cardBackground,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            'Medical Guideline Assistant',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Get instant access to evidence-based clinical guidelines. Ask me about diagnosis protocols, treatment recommendations, or best practices.',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // Suggested Topics Header
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SUGGESTED FOR YOU',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Topic Cards
          ...topics.map((topic) => _buildTopicCard(context, theme, topic)),

          // Fallback topics if API returns empty
          if (topics.isEmpty) ...[
            _buildTopicCard(
              context,
              theme,
              const GuidelineSuggestedTopic(
                icon: 'favorite',
                title: 'Hypertension management',
                subtitle: 'Guidelines & protocol updates',
                query:
                    'What are the latest hypertension management guidelines?',
              ),
            ),
            _buildTopicCard(
              context,
              theme,
              const GuidelineSuggestedTopic(
                icon: 'bloodtype',
                title: 'Type 2 Diabetes protocol',
                subtitle: 'Treatment recommendations',
                query:
                    'What are the current Type 2 Diabetes treatment protocols?',
              ),
            ),
            _buildTopicCard(
              context,
              theme,
              const GuidelineSuggestedTopic(
                icon: 'pulmonology',
                title: 'Asthma management',
                subtitle: 'Recent clinical protocols',
                query: 'What are the latest asthma management protocols?',
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTopicCard(
    BuildContext context,
    OneUITheme theme,
    GuidelineSuggestedTopic topic,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => onTopicTap(topic.query),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _getTopicColor(topic.icon).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTopicIcon(topic.icon),
                    color: _getTopicColor(topic.icon),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        topic.subtitle,
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: theme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTopicIcon(String iconName) {
    switch (iconName) {
      case 'favorite':
        return Icons.favorite_rounded;
      case 'bloodtype':
        return Icons.bloodtype_rounded;
      case 'pulmonology':
        return Icons.air_rounded;
      case 'oncology':
        return Icons.grid_view_rounded;
      default:
        return Icons.medical_information_rounded;
    }
  }

  Color _getTopicColor(String iconName) {
    switch (iconName) {
      case 'favorite':
        return const Color(0xFFFF6B6B);
      case 'bloodtype':
        return const Color(0xFF0A84FF);
      case 'pulmonology':
        return const Color(0xFF34C759);
      case 'oncology':
        return const Color(0xFFFF9500);
      default:
        return const Color(0xFF5856D6);
    }
  }
}
