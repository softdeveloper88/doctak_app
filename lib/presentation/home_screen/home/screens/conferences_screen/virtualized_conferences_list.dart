import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/bloc/conference_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/bloc/conference_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/memory_optimized_conference_item.dart';
import 'package:doctak_app/widgets/shimmer_widget/conferences_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VirtualizedConferencesList extends StatefulWidget {
  final ConferenceBloc conferenceBloc;
  final ScrollController? scrollController;

  const VirtualizedConferencesList({
    super.key,
    required this.conferenceBloc,
    this.scrollController,
  });

  @override
  State<VirtualizedConferencesList> createState() => _VirtualizedConferencesListState();
}

class _VirtualizedConferencesListState extends State<VirtualizedConferencesList> {
  // Track which conference items are currently visible for optimization
  final Set<int> _visibleConferenceIndices = {};

  @override
  void dispose() {
    _visibleConferenceIndices.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.conferenceBloc;

    return bloc.conferenceList.isEmpty
        ? _buildEmptyState(context)
        : _buildVirtualizedConferencesList();
  }

  // Empty state widget
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        translation(context).msg_no_conference_found,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // Virtualized list implementation
  Widget _buildVirtualizedConferencesList() {
    final bloc = widget.conferenceBloc;
    
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      itemCount: bloc.conferenceList.length,
      // Using cacheExtent to preload items beyond the visible area
      cacheExtent: 1000,
      itemBuilder: (context, index) {
        // Check if we need to load more data
        if (bloc.pageNumber <= bloc.numberOfPage) {
          if (index == bloc.conferenceList.length - bloc.nextPageTrigger) {
            bloc.add(CheckIfNeedMoreDataEvent(index: index));
          }
        }
        
        // Show shimmer loader at the bottom if loading more
        if (bloc.numberOfPage != bloc.pageNumber - 1 &&
            index >= bloc.conferenceList.length - 1) {
          return SizedBox(
            height: 400,
            child: ConferencesShimmerLoader()
          );
        } 
        // Show ads every 5 items
        else if ((index % 5 == 0 && index != 0) &&
            AppData.isShowGoogleNativeAds) {
          return NativeAdWidget();
        }
        // Regular conference item
        else {
          return _buildLazyLoadConferenceItem(index);
        }
      },
    );
  }

  // Lazy loading conference item implementation
  Widget _buildLazyLoadConferenceItem(int index) {
    return VisibilityDetector(
      key: Key('conference_visibility_${widget.conferenceBloc.conferenceList[index].id}'),
      onVisibilityChanged: (visibilityInfo) {
        final isVisible = visibilityInfo.visibleFraction > 0.1;
        _handleVisibilityChanged(index, isVisible);
      },
      child: MemoryOptimizedConferenceItem(
        conference: widget.conferenceBloc.conferenceList[index],
      ),
    );
  }

  // Track which conferences are visible for optimization
  void _handleVisibilityChanged(int index, bool isVisible) {
    if (isVisible) {
      _visibleConferenceIndices.add(index);
    } else {
      _visibleConferenceIndices.remove(index);
    }
    
    // Can be used for analytics or optimization in the future
  }
}