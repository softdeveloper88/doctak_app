import 'dart:async';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/compose_content_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_handler/share_handler.dart';

/// Payload received when another app shares text/URL/images into DocTak.
class IncomingSharePayload {
  const IncomingSharePayload({
    this.text,
    this.imagePaths = const [],
  });

  final String? text;
  final List<String> imagePaths;

  bool get isEmpty =>
      (text == null || text!.trim().isEmpty) && imagePaths.isEmpty;
}

/// Listens for Android (and iOS Share Extension) share intents and opens the
/// compose screen so the signed-in user can post shared content to their feed.
class IncomingShareService {
  IncomingShareService._();
  static final IncomingShareService instance = IncomingShareService._();

  StreamSubscription<SharedMedia>? _sub;
  bool _started = false;
  IncomingSharePayload? _pending;
  bool _opening = false;

  /// Call once after Flutter bindings are ready (splash / dashboard).
  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final handler = ShareHandler.instance;
      final initial = await handler.getInitialSharedMedia();
      if (initial != null) {
        _pending = _fromSharedMedia(initial);
        await handler.resetInitialSharedMedia();
      }

      _sub = handler.sharedMediaStream.listen((media) {
        _pending = _fromSharedMedia(media);
        unawaited(consumePending());
      });

      await consumePending();
    } catch (e) {
      debugPrint('IncomingShareService: start failed: $e');
    }
  }

  IncomingSharePayload _fromSharedMedia(SharedMedia media) {
    final paths = <String>[];
    for (final attachment in media.attachments ?? const <SharedAttachment?>[]) {
      if (attachment == null) continue;
      if (attachment.type == SharedAttachmentType.image &&
          attachment.path.isNotEmpty) {
        paths.add(attachment.path);
      }
    }
    return IncomingSharePayload(
      text: media.content?.trim(),
      imagePaths: paths,
    );
  }

  Future<bool> _isLoggedIn() async {
    final memory = AppData.userToken;
    if (memory != null && memory.isNotEmpty) return true;
    final stored = await SecureStorageService.instance.getString('token');
    return stored != null && stored.isNotEmpty;
  }

  /// Opens Compose if logged in and a share is waiting.
  Future<void> consumePending() async {
    final payload = _pending;
    if (payload == null || payload.isEmpty || _opening) return;

    if (!await _isLoggedIn()) {
      debugPrint('IncomingShareService: waiting for login before opening share');
      return;
    }

    final nav = NavigatorService.navigatorKey.currentState;
    if (nav == null || !nav.mounted) return;

    _pending = null;
    _opening = true;
    try {
      final body = (payload.text ?? '').trim();
      await nav.push(
        MaterialPageRoute(
          builder: (_) => ComposeContentScreen(
            initialTab: ComposeTab.update,
            initialBody: body.isEmpty ? null : body,
            initialImagePaths: payload.imagePaths,
            onPosted: () {
              toast('Shared to your DocTak feed');
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('IncomingShareService: open composer failed: $e');
      _pending = payload;
    } finally {
      _opening = false;
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }
}
