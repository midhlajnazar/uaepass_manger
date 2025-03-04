import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:uaepass_api/uaepass/const.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'memory_service.dart';

class CustomWebView extends StatefulWidget {
  final String url;
  final String appSchema;
  final bool isProduction;

  const CustomWebView({super.key, required this.url, required this.appSchema, required this.isProduction});

  @override
  State<CustomWebView> createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView> {
  late WebViewController controller;
  String? successUrl;
  late StreamSubscription<FGBGType> subscription;

  // Staging credentials for UAE Pass API
  final String stagingClientId = 'moca_smart_mob_stage';
  final String stagingClientSecret = 'ecWZfTxaFPAnhkGs';

  // Production credentials for UAE Pass API
  final String productionClientId = 'moca_smart_app_prod';
  final String prodClientSecret = 'PzOFlk5D35GTN47u';

  // Common configuration
  final String spcName = 'MOCA Smart MOB'; // Service provider name
  final String redirectUrl = 'mocaapp://com.exarcplus.pmo/uaepass'; // Redirect URL for UAE Pass
  final String redirectUrlSchema = 'mocaapp'; // Red

  @override
  void dispose() {
    subscription.cancel();
    controller.clearLocalStorage();
    controller.clearCache();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    subscription = FGBGEvents.instance.stream.listen((event) {
      if (event == FGBGType.foreground) {
        if (successUrl != null) {
          final decoded = Uri.decodeFull(successUrl!);
          controller.loadRequest(Uri.parse(decoded));
        }
      }
    });
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..clearCache()
      ..clearLocalStorage()
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: onNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
    super.initState();
  }

  Future<NavigationDecision> onNavigationRequest(NavigationRequest request) async {
    String url = request.url.toString();
    print('fucking url: $url');
    if (url.contains('uaepass://')) {
      Uri uri = Uri.parse(url);
      String? successURL = uri.queryParameters['successurl'];
      successUrl = successURL;
      final newUrl = '${Const.uaePassScheme(widget.isProduction)}${uri.host}${uri.path}';
      String u = "$newUrl?successurl=$redirectUrlSchema://success"
          "&failureurl=$redirectUrlSchema://failure"
          "&closeondone=true";

      await launchUrl(Uri.parse(u));
      return NavigationDecision.prevent;
    }

    if (url.contains('code=')) {
      String code = Uri.parse(url).queryParameters['code']!;
      MemoryService.instance.accessCode = code;
      print('fucking code: $code');
      Navigator.of(context).pop(code);
      return NavigationDecision.prevent;
    } else if (url.contains('cancelled')) {
      if (!url.contains('logout')) {
        Navigator.pop(context);
        return NavigationDecision.prevent;
      }
    }
    return NavigationDecision.navigate;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}
