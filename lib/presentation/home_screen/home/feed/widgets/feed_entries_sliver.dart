import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/bloc/feed_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_entry_view.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_offline_banner.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/post_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Renders home feed entries inside a [CustomScrollView] sliver for smooth,
/// lazy-built scrolling (no eager [Column] of all cards).
class FeedEntriesSliver extends StatelessWidget {
  final FeedBloc bloc;
  final HomeBloc? homeBloc;

  const FeedEntriesSliver({
    super.key,
    required this.bloc,
    this.homeBloc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedBloc, FeedState>(
      bloc: bloc,
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          (previous is FeedLoaded &&
              current is FeedLoaded &&
              (previous.entries.length != current.entries.length ||
                  previous.isPaginating != current.isPaginating ||
                  previous.hasMore != current.hasMore ||
                  !identical(previous.entries, current.entries))) ||
          (current is FeedLoaded && bloc.showOfflineBanner),
      builder: (context, state) {
        final theme = OneUITheme.of(context);

        if (bloc.showInitialShimmer) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: PostShimmerLoader(itemCount: 4),
            ),
          );
        }

        if (state is FeedError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: RetryWidget(
                errorMessage: translation(context).msg_no_internet_connection,
                onRetry: () => bloc.add(const FeedLoadRequested(refresh: true)),
              ),
            ),
          );
        }

        if (state is FeedEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.dynamic_feed_outlined,
                        size: 56, color: theme.textSecondary),
                    const SizedBox(height: 12),
                    Text('No posts yet', style: theme.titleSmall),
                    const SizedBox(height: 4),
                    Text('Be the first to share something',
                        style: theme.bodySecondary),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is FeedLoaded) {
          return _buildLoadedSliver(context, state);
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildLoadedSliver(BuildContext context, FeedLoaded state) {
    final theme = OneUITheme.of(context);
    final entries = state.entries;
    final showOfflineBanner = bloc.showOfflineBanner;
    final extra = (state.isPaginating ? 1 : 0) +
        (!state.hasMore && !state.isPaginating ? 1 : 0) +
        (showOfflineBanner ? 1 : 0);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (showOfflineBanner && index == 0) {
            return FeedOfflineBanner(
              onRetry: () =>
                  bloc.add(const FeedLoadRequested(refresh: true)),
            );
          }

          final entryIndex = showOfflineBanner ? index - 1 : index;
          if (entryIndex < entries.length) {
            final entry = entries[entryIndex];
            return RepaintBoundary(
              key: ValueKey(entry.dedupeKey),
              child: FeedEntryView(
                entry,
                onFeedChanged: () =>
                    bloc.add(const FeedLoadRequested(refresh: true)),
                homeBloc: homeBloc,
              ),
            );
          }

          final footerIndex = entryIndex - entries.length;
          if (state.isPaginating && footerIndex == 0) {
            return const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 12),
              child: PostShimmerLoader(itemCount: 2),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                "You're all caught up",
                style: theme.bodySecondary,
              ),
            ),
          );
        },
        childCount: entries.length + extra,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
      ),
    );
  }
}
