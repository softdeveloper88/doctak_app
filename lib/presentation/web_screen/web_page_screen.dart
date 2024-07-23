import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebPageScreen extends StatefulWidget {
  String url;
  String page_name;
  String htmlString;
  bool hasHeaders;
  bool isHtml;

  WebPageScreen({
    Key? key,
    this.url = '',
    this.page_name = '',
    this.htmlString = '',
    this.hasHeaders = false,
    this.isHtml = false,
  }) : super(key: key);

  @override
  State<WebPageScreen> createState() => _WebPageScreenState();
}

class _WebPageScreenState extends State<WebPageScreen> {
  WebViewController? _webViewController = WebViewController();
  bool isDownloadingQRCode = false;
  bool isHomeIcon = false;

  @override
  void initState() {
    webViewRequest();
    super.initState();
  }

  webViewRequest() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) async {
            // var urlPayment= url.contains('bypass_payment');
            // print('onPageStarted $url');
            // if (url=='${AppConfig.BASE_URL}/api/ipay88/response') {
            //   setState(() {
            //     isHomeIcon=true;
            //   });
            //   //  https://carkee.my/api/v2/ipay-webview/7/bypass_payment
            // }else if (urlPayment) {
            //   setState(() {
            //     isHomeIcon=true;
            //   });
            // }
            // if(url=='${AppConfig.BASE_URL}/api/ipay88/response'){
            //   await getApiResponse(url);
            //   // Navigator.push(
            //   //   context,
            //   //   MaterialPageRoute(
            //   //     builder: (context) => const MainScreen(),
            //   //   ),
            //   // );
            // }
          },
          onPageFinished: (String url) {
            print('onPageFinished $url');
          },
          onWebResourceError: (WebResourceError error) {
            print('onWebResourceError $error');
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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text(widget.page_name), actions: []),
        body: buildBody(),
      ),
    );
  }

  buildBody() {
    if (_webViewController != null) {
      return SizedBox.expand(
        child: WebViewWidget(
          controller: _webViewController!,
        ),
      );
    } else {
      const SizedBox.expand(
        child: Center(
          child: Text(
            'Something went wrong',
          ),
        ),
      );
    }
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      // backgrou   ndColor: Colors.white,
      // centerTitle: true,
      leading: Builder(
        builder: (context) => const BackButton(),
      ),
      title: Text(
        widget.page_name,
        // style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
