import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/memory_optimized_guideline_item.dart';
import 'package:doctak_app/widgets/shimmer_widget/guidelines_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VirtualizedGuidelinesList extends StatefulWidget {
  final GuidelinesBloc guidelineBloc;
  final ScrollController? scrollController;

  const VirtualizedGuidelinesList({
    super.key,
    required this.guidelineBloc,
    this.scrollController,
  });

  @override
  State<VirtualizedGuidelinesList> createState() =>
      _VirtualizedGuidelinesListState();
}

class _VirtualizedGuidelinesListState extends State<VirtualizedGuidelinesList> {
  // Track which guideline items are currently visible for optimization
  final Set<int> _visibleGuidelineIndices = {};

  @override
  void dispose() {
    _visibleGuidelineIndices.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.guidelineBloc;

    return bloc.guidelinesList.isEmpty
        ? _buildEmptyState(context)
        : _buildVirtualizedGuidelinesList();
  }

  // Empty state widget
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No guidelines found",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Virtualized list implementation
  Widget _buildVirtualizedGuidelinesList() {
    final bloc = widget.guidelineBloc;

    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        top: 10,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      itemCount: bloc.guidelinesList.length,
      // Using cacheExtent to preload items beyond the visible area
      cacheExtent: 1000,
      itemBuilder: (context, index) {
        // Check if we need to load more data
        if (bloc.pageNumber <= bloc.numberOfPage) {
          if (index == bloc.guidelinesList.length - bloc.nextPageTrigger) {
            bloc.add(CheckIfNeedMoreDataEvent(index: index));
          }
        }

        // Show shimmer loader at the bottom if loading more
        if (bloc.numberOfPage != bloc.pageNumber - 1 &&
            index >= bloc.guidelinesList.length - 1) {
          return const SizedBox(height: 400, child: GuidelinesShimmerLoader());
        }
        // Show ads every 5 items
        else if ((index % 5 == 0 && index != 0) &&
            AppData.isShowGoogleNativeAds) {
          return NativeAdWidget();
        }
        // Regular guideline item
        else {
          return _buildLazyLoadGuidelineItem(index);
        }
      },
    );
  }

  // Lazy loading guideline item implementation
  Widget _buildLazyLoadGuidelineItem(int index) {
    return VisibilityDetector(
      key: Key(
        'guideline_visibility_${widget.guidelineBloc.guidelinesList[index].id}',
      ),
      onVisibilityChanged: (visibilityInfo) {
        final isVisible = visibilityInfo.visibleFraction > 0.1;
        _handleVisibilityChanged(index, isVisible);
      },
      child: MemoryOptimizedGuidelineItem(
        guideline: widget.guidelineBloc.guidelinesList[index],
      ),
    );
  }

  // Track which guidelines are visible for optimization
  void _handleVisibilityChanged(int index, bool isVisible) {
    if (isVisible) {
      _visibleGuidelineIndices.add(index);
    } else {
      _visibleGuidelineIndices.remove(index);
    }

    // Can be used for analytics or optimization in the future
  }
}
