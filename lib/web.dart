import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebPage extends StatefulWidget {
  final String url;
  final String? title;

  const WebPage(this.url, {Key? key, this.title}) : super(key: key);

  @override
  _WebPageState createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  late WebViewController controller;

  @override
  void initState() {
    super.initState();
    loadUrl();
  }

  void loadUrl() async {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.title != null && widget.title!.isNotEmpty
          ? AppBar(title: Text(widget.title!))
          : null,
      body: WebViewWidget(controller: controller),
    );
  }
}
