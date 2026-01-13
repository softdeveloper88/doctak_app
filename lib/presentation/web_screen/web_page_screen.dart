import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebPageScreen extends StatefulWidget {
  final String url;
  final String pageName;
  final String htmlString;
  final bool hasHeaders;
  final bool isHtml;

  const WebPageScreen({
    super.key,
    this.url = '',
    this.pageName = '',
    this.htmlString = '',
    this.hasHeaders = false,
    this.isHtml = false,
  });

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
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
              if (progress == 100) {
                _isLoading = false;
              }
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: DoctakAppBar(
          title: widget.pageName,
          titleIcon: Icons.web_rounded,
        ),
        body: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(OneUITheme theme) {
    if (_webViewController != null) {
      return Stack(
        children: [
          // WebView
          Container(
            color: theme.cardBackground,
            child: WebViewWidget(controller: _webViewController!),
          ),

          // Loading indicator
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: theme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                    minHeight: 3,
                  ),
                ],
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
                decoration: BoxDecoration(
                  color: theme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: theme.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                translation(context).msg_webview_error,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}
