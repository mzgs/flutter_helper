import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:mzgs_flutter_helper/flutter_helper.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;

class WebParser {
  late WebViewController controller;
  bool _pageLoaded = false;
  bool isDesktop = false;

  WebParser({this.isDesktop = false});

  void init({
    void Function()? onFinished,
  }) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) async {
            if (_pageLoaded) {
              return;
            }
            _pageLoaded = true;

            onFinished?.call();
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    if (isDesktop) {
      controller.setUserAgent(
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15");
    }
  }

  setFetchListener(Function(String message) onFetch) {
    controller.addJavaScriptChannel("FlutterChannel",
        onMessageReceived: (message) {
      onFetch(message.message);
    });
  }

  Future<String> getHtml({String query = "", String queryAll = ""}) async {
    if (query == "") {
      return decodeUnicodeEscapeSequences(
          (await controller.runJavaScriptReturningResult(
                  "document.querySelector('$query').outerHTML"))
              .toString());
    }

    if (queryAll == "") {
      return decodeUnicodeEscapeSequences(
          (await controller.runJavaScriptReturningResult(
                  "document.querySelectorAll('$queryAll').outerHTML"))
              .toString());
    }

    return decodeUnicodeEscapeSequences((await controller
            .runJavaScriptReturningResult("document.documentElement.outerHTML"))
        .toString());
  }

  Future<dom.Document> parseHTML(
      {String query = "", String queryAll = ""}) async {
    return parse(await getHtml(query: query, queryAll: queryAll));
  }

  dom.Document parseHTMLtext(String html) {
    return parse(html);
  }

  Future<void> waitForElement(String query, {int timeout = 10}) async {
    for (var i = 0; i < timeout; i++) {
      var hasInput = await controller.runJavaScriptReturningResult(
              'document.querySelector("$query").outerHTML') !=
          "null";

      if (hasInput) {
        break;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> waitForText(String text, {int timeout = 10}) async {
    for (var i = 0; i < timeout; i++) {
      var contains = (await getHtml()).contains(text);

      if (contains) {
        break;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void loadUrl(String url, {bool runPageLoad = true}) {
    if (runPageLoad) {
      _pageLoaded = false;
    }
    controller.loadRequest(Uri.parse(url));
  }

  void goToGoogle() {
    loadUrl("https://www.google.com/", runPageLoad: false);
  }

  static String decodeUnicodeEscapeSequences(String input) {
    return input
        .replaceAllMapped(
            RegExp(r'\\u([0-9A-Fa-f]{4})'),
            (match) =>
                String.fromCharCode(int.parse(match.group(1)!, radix: 16)))
        .replaceAll('\\"', '"');
  }

  Future wait(int seconds) async {
    await Future.delayed(Duration(seconds: seconds));
  }

  void initFetchJs() {
    controller.runJavaScript('''
                  (function() {
                    // Intercept fetch API calls
                    const originalFetch = window.fetch;
                    window.fetch = function() {
                    
                      FlutterChannel.postMessage(JSON.stringify(arguments));
                      return originalFetch.apply(this, arguments);
                    };
                    
                    // Intercept XMLHttpRequest calls
                    const originalOpen = XMLHttpRequest.prototype.open;
                    XMLHttpRequest.prototype.open = function() {
                      FlutterChannel.postMessage(JSON.stringify(arguments));
                      return originalOpen.apply(this, arguments);
                    };
                  })();
                ''');
  }

  static WebParser headlessBrowse(String url,
      {void Function(WebParser web)? onFinished,
      isDesktop = true,
      bool showWebviewUI = false}) {
    var webParser = WebParser(isDesktop: isDesktop);

    webParser.init(onFinished: () {
      onFinished?.call(webParser);
    });

    webParser.loadUrl(url);

    Helper.widgetsBuildFinished(() {
      Get.to(() => WebShowWidget(
          webViewController: webParser.controller, showWebUI: showWebviewUI));
    });

    return webParser;
  }
}

class WebShowWidget extends StatefulWidget {
  final WebViewController webViewController;
  final bool showWebUI;

  WebShowWidget({required this.webViewController, required this.showWebUI});

  @override
  _WebShowWidgetState createState() => _WebShowWidgetState();
}

class _WebShowWidgetState extends State<WebShowWidget> {
  @override
  void initState() {
    super.initState();
    if (!widget.showWebUI) {
      context.closeActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('WebView with Controller'),
        ),
        body: WebViewWidget(controller: widget.webViewController));
  }
}
