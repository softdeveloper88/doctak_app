import 'package:doctak_app/core/utils/deep_link_service.dart';
export 'package:doctak_app/core/utils/deep_link_service.dart' show DeepLinkService, deepLinkService;

/// Legacy dynamic link creation functions (deprecated)
/// Use DeepLinkService static methods instead:
/// - DeepLinkService.sharePost()
/// - DeepLinkService.shareJob()
/// - DeepLinkService.shareConference()
/// - DeepLinkService.shareMeeting()

/// Create and share a post link
/// @deprecated Use DeepLinkService.sharePost() instead
Future<void> createDynamicLink(String postTitle, String postUrl, String imageUrl) async {
  // Extract post ID from URL if possible
  final uri = Uri.tryParse(postUrl);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    final postIdStr = uri.pathSegments.lastWhere((segment) => int.tryParse(segment) != null, orElse: () => '');
    final postId = int.tryParse(postIdStr);

    if (postId != null) {
      await DeepLinkService.sharePost(postId: postId, title: postTitle);
      return;
    }
  }

  // Fallback: Share the original URL
  await DeepLinkService.sharePost(
    postId: 0, // Will just use base URL
    title: postTitle,
    description: postUrl,
  );
}

/// Create and share a job link
Future<void> createJobLink({required String jobId, String? title, String? company, String? location}) async {
  await DeepLinkService.shareJob(jobId: jobId, title: title, company: company, location: location);
}

/// Create and share a conference link
Future<void> createConferenceLink({required String conferenceId, String? title, String? date, String? location}) async {
  await DeepLinkService.shareConference(conferenceId: conferenceId, title: title, date: date, location: location);
}

/// Create and share a meeting link
Future<void> createMeetingLink({required String meetingId, String? title, String? date, String? time}) async {
  await DeepLinkService.shareMeeting(meetingId: meetingId, title: title, date: date, time: time);
}

/// Get a shareable link for a post
String getPostShareLink(int postId) {
  return DeepLinkService.generatePostLink(postId);
}

/// Get a shareable link for a job
String getJobShareLink(String jobId) {
  return DeepLinkService.generateJobLink(jobId);
}

/// Get a shareable link for a conference
String getConferenceShareLink(String conferenceId) {
  return DeepLinkService.generateConferenceLink(conferenceId);
}

/// Get a shareable link for a meeting
String getMeetingShareLink(String meetingId) {
  return DeepLinkService.generateMeetingLink(meetingId);
}
