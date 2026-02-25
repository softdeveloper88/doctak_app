part of 'story_bloc.dart';

/// Events for Story BLoC
abstract class StoryEvent {
  const StoryEvent();
}

/// Load the story feed (all active stories from connected users)
class LoadStoryFeedEvent extends StoryEvent {
  const LoadStoryFeedEvent();
}

/// Create a new story
class CreateStoryEvent extends StoryEvent {
  final String type; // 'image', 'video', 'text'
  final String? mediaPath;
  final String? content;
  final String? backgroundColor;
  final int? duration;
  final String? privacy;

  const CreateStoryEvent({
    required this.type,
    this.mediaPath,
    this.content,
    this.backgroundColor,
    this.duration,
    this.privacy,
  });
}

/// Mark a story as viewed
class MarkStoryViewedEvent extends StoryEvent {
  final int storyId;
  const MarkStoryViewedEvent({required this.storyId});
}

/// Delete an own story
class DeleteStoryEvent extends StoryEvent {
  final int storyId;
  const DeleteStoryEvent({required this.storyId});
}

/// Load viewers for a specific story
class LoadStoryViewersEvent extends StoryEvent {
  final int storyId;
  const LoadStoryViewersEvent({required this.storyId});
}
