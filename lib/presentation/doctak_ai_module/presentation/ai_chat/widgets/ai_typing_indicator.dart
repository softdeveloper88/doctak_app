import 'package:flutter/material.dart';

class AiTypingIndicator extends StatefulWidget {
  final bool webSearch;

  const AiTypingIndicator({super.key, this.webSearch = false});

  @override
  State<AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<AiTypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

    _animations = List.generate(
      3,
      (index) => Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.2 * index, 0.2 * index + 0.6, curve: Curves.easeInOut),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Icon(Icons.psychology_rounded, size: 18, color: Colors.blue[600]),
          ),

          const SizedBox(width: 8),

          // Typing indicator + web search info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.1), width: 1),
                    boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.05), offset: const Offset(0, 2), blurRadius: 8, spreadRadius: 0)],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (index) => AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 6,
                            height: 6 + _animations[index].value,
                            decoration: BoxDecoration(color: Colors.blue[600]!.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(3)),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Web search info
                if (widget.webSearch)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(
                      children: [
                        // Web search icon
                        Icon(Icons.search, size: 14, color: Colors.blue[600]!.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          'Searching the web...',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Poppins', color: Colors.blue[600]!.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
