import 'package:flutter/material.dart';

/// Coordinates tab content with [NestedScrollView] so pinned tabs do not leave
/// a gap above the first list item.
class GroupNestedTabScroll extends StatelessWidget {
  final List<Widget> slivers;

  const GroupNestedTabScroll({super.key, required this.slivers});

  static SliverOverlapInjector overlapInjector(BuildContext context) {
    return SliverOverlapInjector(
      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            overlapInjector(context),
            ...slivers,
          ],
        );
      },
    );
  }
}
