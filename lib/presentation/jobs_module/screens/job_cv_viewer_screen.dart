import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/auth_token_service.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Downloads a private CV (Bearer auth) and opens it inside the app.
Future<void> openJobCvInApp(
  BuildContext context, {
  required String? cvUrl,
  String? title,
  String? cvPreview,
}) async {
  final resolved = AppData.fullImageUrl(cvUrl);
  if (resolved.isEmpty) {
    if (cvPreview != null && cvPreview.trim().isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JobCvViewerScreen.preview(
            title: title ?? 'CV',
            previewText: cvPreview,
          ),
        ),
      );
      return;
    }
    toast('No CV available');
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => JobCvViewerScreen(
        url: resolved,
        title: title ?? 'CV',
        cvPreview: cvPreview,
      ),
    ),
  );
}

class JobCvViewerScreen extends StatefulWidget {
  const JobCvViewerScreen({
    super.key,
    required this.url,
    this.title = 'CV',
    this.cvPreview,
  }) : previewText = null;

  const JobCvViewerScreen.preview({
    super.key,
    required this.title,
    required this.previewText,
  })  : url = '',
        cvPreview = null;

  final String url;
  final String title;
  final String? cvPreview;
  final String? previewText;

  @override
  State<JobCvViewerScreen> createState() => _JobCvViewerScreenState();
}

class _JobCvViewerScreenState extends State<JobCvViewerScreen> {
  bool _loading = true;
  String? _error;
  File? _file;
  String? _mime;
  String? _textPreview;
  WebViewController? _webView;

  @override
  void initState() {
    super.initState();
    if (widget.previewText != null) {
      _loading = false;
    } else {
      _download();
    }
  }

  List<String> _candidateUrls(String primary) {
    final urls = <String>{primary};
    try {
      final uri = Uri.parse(primary);
      final path = uri.path;
      if (path.contains('/profile-media/')) {
        urls.add(primary.replaceFirst('/profile-media/', '/r2-media/'));
      } else if (path.contains('/r2-media/')) {
        urls.add(primary.replaceFirst('/r2-media/', '/profile-media/'));
      }
    } catch (_) {}
    return urls.toList();
  }

  Future<void> _download() async {
    setState(() {
      _loading = true;
      _error = null;
      _textPreview = null;
      _webView = null;
    });
    try {
      final headers = await AuthTokenService.instance.authHeaders(
        includeContentType: false,
      );
      headers[HttpHeaders.acceptHeader] = '*/*';

      final dir = await getTemporaryDirectory();
      final name = _fileNameFromUrl(widget.url);
      final path = p.join(
        dir.path,
        'job_cv_${DateTime.now().millisecondsSinceEpoch}_$name',
      );

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
          // Accept all statuses so we can map them to friendly errors /
          // try fallback URLs without Dio throwing raw exception text.
          validateStatus: (_) => true,
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

      Response<List<int>>? response;
      Object? lastError;
      for (final url in _candidateUrls(widget.url)) {
        try {
          final res = await dio.get<List<int>>(
            url,
            options: Options(headers: headers),
          );
          if (res.statusCode == 200 && res.data != null && res.data!.isNotEmpty) {
            response = res;
            break;
          }
          if (res.statusCode == 401 || res.statusCode == 403) {
            throw Exception('You don’t have permission to view this CV.');
          }
          lastError = Exception(_friendlyStatus(res.statusCode));
        } on DioException catch (e) {
          lastError = e;
        }
      }

      if (response == null) {
        throw lastError ?? Exception('Couldn’t download CV.');
      }

      final bytes = response.data!;
      // Guard against JSON error payloads served as 200 in some proxies.
      final head = String.fromCharCodes(bytes.take(64));
      final trimmed = head.trimLeft();
      if ((trimmed.startsWith('{') || trimmed.startsWith('<')) &&
          (trimmed.contains('"success"') || trimmed.contains('<html'))) {
        throw Exception('CV unavailable. Try again later.');
      }

      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      final contentType = response.headers.value('content-type');
      final mime = _resolveMime(name, contentType);

      if (!mounted) return;

      if (_isTextMime(mime)) {
        setState(() {
          _file = file;
          _mime = mime;
          _textPreview = String.fromCharCodes(bytes);
          _loading = false;
        });
        return;
      }

      setState(() {
        _file = file;
        _mime = mime;
        _loading = false;
      });

      if (mime == 'application/pdf') {
        await _initPdfWebView(file);
      } else if (!_isImageMime(mime)) {
        // Office / other docs: open with the system viewer.
        await OpenFilex.open(file.path, type: mime);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyStatus(int? code) {
    switch (code) {
      case 404:
        return 'CV file was not found on the server.';
      case 401:
      case 403:
        return 'You don’t have permission to view this CV.';
      case 500:
      case 502:
      case 503:
        return 'Server error while loading the CV. Please retry.';
      default:
        return 'Couldn’t download CV${code != null ? ' ($code)' : ''}.';
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code != null) return _friendlyStatus(code);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Connection timed out. Check your network and retry.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'No internet connection. Check your network and retry.';
      }
      return 'Couldn’t download CV. Please retry.';
    }
    final raw = e.toString().replaceFirst('Exception: ', '');
    if (raw.contains('DioException') || raw.contains('status code')) {
      return 'Couldn’t download CV. Please retry.';
    }
    return raw;
  }

  Future<void> _initPdfWebView(File file) async {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white);

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(kDebugMode);
    }

    await controller.loadFile(file.path);
    if (!mounted) return;
    setState(() => _webView = controller);
  }

  Future<void> _openExternally() async {
    final file = _file;
    if (file == null) return;
    final result = await OpenFilex.open(file.path, type: _mime);
    if (result.type != ResultType.done && mounted) {
      toast(result.message);
    }
  }

  String _fileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'cv';
      return last.isEmpty ? 'cv' : Uri.decodeComponent(last);
    } catch (_) {
      return 'cv';
    }
  }

  String _resolveMime(String fileName, String? contentType) {
    final ct = (contentType ?? '').split(';').first.trim().toLowerCase();
    if (ct.isNotEmpty &&
        ct != 'application/octet-stream' &&
        ct != 'application/json' &&
        ct != 'text/html') {
      return ct;
    }
    switch (p.extension(fileName).toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.odt':
        return 'application/vnd.oasis.opendocument.text';
      case '.rtf':
        return 'application/rtf';
      case '.txt':
        return 'text/plain';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  bool _isImageMime(String? mime) =>
      mime != null && mime.startsWith('image/');

  bool _isTextMime(String? mime) =>
      mime == 'text/plain' || mime == 'application/rtf';

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final previewOnly = widget.previewText != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: widget.title,
        subtitle: 'Curriculum Vitae',
        backgroundColor: theme.cardBackground,
        showShadow: false,
        titleColor: theme.textPrimary,
        titleFontWeight: FontWeight.w700,
        actions: [
          if (_file != null)
            IconButton(
              tooltip: 'Open with…',
              onPressed: _openExternally,
              icon: Icon(Icons.open_in_new_rounded, color: theme.primary),
            ),
        ],
      ),
      body: previewOnly
          ? _PreviewBody(text: widget.previewText!, theme: theme)
          : _loading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: theme.primary),
                      const SizedBox(height: 14),
                      Text(
                        'Loading CV…',
                        style: theme.bodySecondary,
                      ),
                    ],
                  ),
                )
              : _error != null
                  ? _ErrorBody(
                      message: _error!,
                      onRetry: _download,
                      theme: theme,
                    )
                  : _textPreview != null
                      ? _PreviewBody(text: _textPreview!, theme: theme)
                      : _isImageMime(_mime) && _file != null
                          ? InteractiveViewer(
                              child: Center(
                                child: Image.file(_file!, fit: BoxFit.contain),
                              ),
                            )
                          : _mime == 'application/pdf' && _webView != null
                              ? WebViewWidget(controller: _webView!)
                              : _OfficeDocBody(
                                  fileName: _file != null
                                      ? p.basename(_file!.path)
                                      : 'CV',
                                  mime: _mime,
                                  onOpen: _openExternally,
                                  theme: theme,
                                ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.text, required this.theme});

  final String text;
  final OneUITheme theme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: JobsTheme.listPadding(context, top: 16, horizontal: 16),
      child: Text(text, style: theme.bodyMedium),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.theme,
  });

  final String message;
  final VoidCallback onRetry;
  final OneUITheme theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 48, color: theme.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Couldn’t open CV',
              style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.bodySecondary,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: theme.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficeDocBody extends StatelessWidget {
  const _OfficeDocBody({
    required this.fileName,
    required this.mime,
    required this.onOpen,
    required this.theme,
  });

  final String fileName;
  final String? mime;
  final VoidCallback onOpen;
  final OneUITheme theme;

  @override
  Widget build(BuildContext context) {
    final ext = p.extension(fileName).replaceAll('.', '').toUpperCase();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(Icons.description_rounded, size: 42, color: theme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              fileName.contains('_') ? fileName.split('_').last : fileName,
              textAlign: TextAlign.center,
              style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              ext.isEmpty ? (mime ?? 'Document') : '$ext document',
              style: theme.caption.copyWith(color: theme.textSecondary),
            ),
            const SizedBox(height: 10),
            Text(
              'This file opens in a system viewer from this screen.',
              textAlign: TextAlign.center,
              style: theme.bodySecondary,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open document'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 48),
                backgroundColor: theme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
