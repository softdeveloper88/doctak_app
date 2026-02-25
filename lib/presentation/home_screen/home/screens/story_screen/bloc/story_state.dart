part of 'story_bloc.dart';

/// States for Story BLoC
abstract class StoryState {
  const StoryState();
}

/// Initial state before any loading
class StoryInitialState extends StoryState {
  const StoryInitialState();
}

/// Loading stories feed
class StoryLoadingState extends StoryState {
  const StoryLoadingState();
}

/// Stories feed loaded successfully
class StoryFeedLoadedState extends StoryState {
  final List<StoryGroupModel> storyGroups;
  const StoryFeedLoadedState({required this.storyGroups});
}

/// Creating a new story (upload in progress)
class StoryCreatingState extends StoryState {
  const StoryCreatingState();
}

/// Story created successfully
class StoryCreatedState extends StoryState {
  final String message;
  const StoryCreatedState({this.message = 'Story created successfully!'});
}

/// Story deleted
class StoryDeletedState extends StoryState {
  const StoryDeletedState();
}

/// Story viewers loaded
class StoryViewersLoadedState extends StoryState {
  final List<StoryViewerModel> viewers;
  final int totalViews;
  const StoryViewersLoadedState({
    required this.viewers,
    required this.totalViews,
  });
}

/// Error state
class StoryErrorState extends StoryState {
  final String message;
  const StoryErrorState({required this.message});
}
