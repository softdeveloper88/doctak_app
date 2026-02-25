import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctak_app/data/apiClient/services/story_api_service.dart';
import 'package:doctak_app/data/models/story_model/story_model.dart';

part 'story_event.dart';
part 'story_state.dart';

class StoryBloc extends Bloc<StoryEvent, StoryState> {
  final StoryApiService _apiService = StoryApiService();

  /// Cached story groups for the feed
  List<StoryGroupModel> storyGroups = [];

  StoryBloc() : super(const StoryInitialState()) {
    on<LoadStoryFeedEvent>(_onLoadStoryFeed);
    on<CreateStoryEvent>(_onCreateStory);
    on<MarkStoryViewedEvent>(_onMarkStoryViewed);
    on<DeleteStoryEvent>(_onDeleteStory);
    on<LoadStoryViewersEvent>(_onLoadStoryViewers);
  }

  Future<void> _onLoadStoryFeed(
    LoadStoryFeedEvent event,
    Emitter<StoryState> emit,
  ) async {
    try {
      // Only show loading if no cached data
      if (storyGroups.isEmpty) {
        emit(const StoryLoadingState());
      }

      final response = await _apiService.getStoryFeed();
      storyGroups = response.data;
      emit(StoryFeedLoadedState(storyGroups: storyGroups));
    } catch (e) {
      print('🔴 StoryBloc._onLoadStoryFeed error: $e');
      // If we have cached data, still show it
      if (storyGroups.isNotEmpty) {
        emit(StoryFeedLoadedState(storyGroups: storyGroups));
      } else {
        emit(StoryErrorState(message: e.toString()));
      }
    }
  }

  Future<void> _onCreateStory(
    CreateStoryEvent event,
    Emitter<StoryState> emit,
  ) async {
    try {
      emit(const StoryCreatingState());

      File? mediaFile;
      if (event.mediaPath != null && event.mediaPath!.isNotEmpty) {
        mediaFile = File(event.mediaPath!);
      }

      await _apiService.createStory(
        type: event.type,
        mediaFile: mediaFile,
        content: event.content,
        backgroundColor: event.backgroundColor,
        duration: event.duration,
        privacy: event.privacy,
      );

      emit(const StoryCreatedState());

      // Reload feed to show new story
      add(const LoadStoryFeedEvent());
    } catch (e) {
      print('🔴 StoryBloc._onCreateStory error: $e');
      emit(StoryErrorState(message: 'Failed to create story: $e'));
    }
  }

  Future<void> _onMarkStoryViewed(
    MarkStoryViewedEvent event,
    Emitter<StoryState> emit,
  ) async {
    // Fire and forget — don't change UI state for view tracking
    await _apiService.markStoryViewed(event.storyId);

    // Update local state to mark as viewed
    for (final group in storyGroups) {
      for (final story in group.stories) {
        if (story.id == event.storyId) {
          // The model is immutable from JSON but we track locally
          break;
        }
      }
    }
  }

  Future<void> _onDeleteStory(
    DeleteStoryEvent event,
    Emitter<StoryState> emit,
  ) async {
    try {
      await _apiService.deleteStory(event.storyId);
      emit(const StoryDeletedState());

      // Reload feed
      add(const LoadStoryFeedEvent());
    } catch (e) {
      print('🔴 StoryBloc._onDeleteStory error: $e');
      emit(StoryErrorState(message: 'Failed to delete story: $e'));
    }
  }

  Future<void> _onLoadStoryViewers(
    LoadStoryViewersEvent event,
    Emitter<StoryState> emit,
  ) async {
    try {
      final viewers = await _apiService.getStoryViewers(event.storyId);
      emit(StoryViewersLoadedState(
        viewers: viewers,
        totalViews: viewers.length,
      ));
    } catch (e) {
      print('🔴 StoryBloc._onLoadStoryViewers error: $e');
      emit(StoryErrorState(message: 'Failed to load viewers: $e'));
    }
  }
}
