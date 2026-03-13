import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebPageScreen extends StatefulWidget {
  final String url;
  final String pageName;
  final String htmlString;
  final bool hasHeaders;
  final bool isHtml;

  const WebPageScreen({super.key, this.url = '', this.pageName = '', this.htmlString = '', this.hasHeaders = false, this.isHtml = false});

  @override
  State<WebPageScreen> createState() => _WebPageScreenState();
}

class _WebPageScreenState extends State<WebPageScreen> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // ── Platform-specific params for best CSS/mixed-content support ──
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    late WebViewController controller;
    controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(
        defaultTargetPlatform == TargetPlatform.iOS
            ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
              'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
            : 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
              if (progress == 100) _isLoading = false;
            });
          },
          onPageStarted: (String url) => setState(() => _isLoading = true),
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            // Inject viewport meta if missing, for proper mobile CSS rendering
            controller.runJavaScript(
              "if (!document.querySelector('meta[name=viewport]')) {"
              "  var m = document.createElement('meta');"
              "  m.name = 'viewport';"
              "  m.content = 'width=device-width, initial-scale=1.0';"
              "  document.head.appendChild(m);"
              "}",
            );
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) =>
              NavigationDecision.navigate,
        ),
      );

    // ── Android-specific: DOM storage + mixed content ──
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      final androidController =
          controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    // Clear any stale cached resources before loading
    controller.clearCache();
    controller.clearLocalStorage();

    if (widget.isHtml && widget.htmlString.isNotEmpty) {
      controller.loadHtmlString(widget.htmlString);
    } else if (widget.url.isNotEmpty) {
      controller.loadRequest(
        Uri.parse(widget.url),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
    }

    _webViewController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: DoctakAppBar(title: widget.pageName, titleIcon: Icons.web_rounded),
        body: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(OneUITheme theme) {
    if (_webViewController != null) {
      return Stack(
        children: [
          // WebView
          WebViewWidget(controller: _webViewController!),

          // Loading indicator
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [LinearProgressIndicator(value: _loadingProgress, backgroundColor: theme.surfaceVariant, valueColor: AlwaysStoppedAnimation<Color>(theme.primary), minHeight: 3)],
              ),
            ),
        ],
      );
    } else {
      return Container(
        color: theme.cardBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: theme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.error_outline_rounded, size: 48, color: theme.error),
              ),
              const SizedBox(height: 16),
              Text(
                translation(context).msg_webview_error,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w500, color: theme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}
