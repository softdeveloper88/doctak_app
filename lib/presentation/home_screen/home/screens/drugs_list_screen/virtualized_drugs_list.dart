import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/ChatDetailScreen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/memory_optimized_drug_item.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/shimmer_widget/drugs_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VirtualizedDrugsList extends StatefulWidget {
  final DrugsBloc drugsBloc;
  final ScrollController? scrollController;

  const VirtualizedDrugsList({
    super.key,
    required this.drugsBloc,
    this.scrollController,
  });

  @override
  State<VirtualizedDrugsList> createState() => _VirtualizedDrugsListState();
}

class _VirtualizedDrugsListState extends State<VirtualizedDrugsList> {
  // Track which drug items are currently visible for optimization
  final Set<int> _visibleDrugIndices = {};

  @override
  void dispose() {
    _visibleDrugIndices.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.drugsBloc;
    final theme = OneUITheme.of(context);

    return bloc.drugsData.isEmpty
        ? _buildEmptyState(context, theme)
        : _buildVirtualizedDrugsList();
  }

  // Empty state widget
  Widget _buildEmptyState(BuildContext context, OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 64, color: theme.textTertiary),
          const SizedBox(height: 16),
          Text(
            translation(context).msg_no_drugs_found,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            translation(context).msg_try_adjusting_filters,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: theme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // Virtualized list implementation
  Widget _buildVirtualizedDrugsList() {
    final bloc = widget.drugsBloc;

    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      itemCount: bloc.drugsData.length,
      // Using cacheExtent to preload items beyond the visible area
      cacheExtent: 1000,
      itemBuilder: (context, index) {
        // Check if we need to load more data
        if (bloc.pageNumber <= bloc.numberOfPage) {
          if (index == bloc.drugsData.length - bloc.nextPageTrigger) {
            bloc.add(CheckIfNeedMoreDataEvent(index: index));
          }
        }

        // Show shimmer loader at the bottom if loading more
        if (bloc.numberOfPage != bloc.pageNumber - 1 &&
            index >= bloc.drugsData.length - 1) {
          return const SizedBox(height: 400, child: DrugsShimmerLoader());
        }
        // Show ads every 5 items
        else if ((index % 5 == 0 && index != 0) &&
            AppData.isShowGoogleNativeAds) {
          return NativeAdWidget();
        }
        // Regular drug item
        else {
          return _buildLazyLoadDrugItem(index);
        }
      },
    );
  }

  // Lazy loading drug item implementation
  Widget _buildLazyLoadDrugItem(int index) {
    return VisibilityDetector(
      key: Key('drug_visibility_${widget.drugsBloc.drugsData[index].id}'),
      onVisibilityChanged: (visibilityInfo) {
        final isVisible = visibilityInfo.visibleFraction > 0.1;
        _handleVisibilityChanged(index, isVisible);
      },
      child: MemoryOptimizedDrugItem(
        drug: widget.drugsBloc.drugsData[index],
        onShowBottomSheet: _showBottomSheet,
      ),
    );
  }

  // Track which drugs are visible for optimization
  void _handleVisibilityChanged(int index, bool isVisible) {
    if (isVisible) {
      _visibleDrugIndices.add(index);
    } else {
      _visibleDrugIndices.remove(index);
    }

    // Can be used for analytics or optimization in the future
  }

  // Bottom sheet for drug details
  void _showBottomSheet(
    BuildContext context,
    String genericName,
    String question,
  ) {
    showModalBottomSheet(
      showDragHandle: true,
      enableDrag: true,
      isScrollControlled: true,
      isDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.9,
              maxChildSize: 1.0,
              expand: false,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ChatDetailScreen(
                        isFromMainScreen: false,
                        question: '$question $genericName',
                      ),
                    );
                  },
            );
          },
        );
      },
    );
  }
}
