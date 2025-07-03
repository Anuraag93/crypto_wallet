import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HyperliquidWebView extends StatefulWidget {
  final String privateKeyBase64;

  const HyperliquidWebView({super.key, required this.privateKeyBase64});

  @override
  State<HyperliquidWebView> createState() => _HyperliquidWebViewState();
}

class _HyperliquidWebViewState extends State<HyperliquidWebView> {
  late WebViewController _controller;
  final storage = FlutterSecureStorage();
  String jsLog = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('FromJS', onMessageReceived: handleJSMessage)
      ..loadHtmlString(_initialHTML);
  }

  void handleJSMessage(JavaScriptMessage message) {
    setState(() {
      jsLog += '\nJS Message: ${message.message}';
    });
    // Example: Expecting JSON with type and payload
    final decoded = jsonDecode(message.message);
    if (decoded['type'] == 'log') {
      print('JS log: ${decoded['payload']}');
    }
  }

  Future<void> injectPrivateKey() async {
    final script =
        """
      window.privateKey = '${widget.privateKeyBase64}';
      FromJS.postMessage(JSON.stringify({ type: 'log', payload: 'Private key injected' }));
    """;
    await _controller.runJavaScript(script);
  }

  Future<void> triggerSignDemo() async {
    const jsCode = """
      async function demoSign() {
        const privateKey = window.privateKey;
        if (!privateKey) {
          FromJS.postMessage(JSON.stringify({ type: 'log', payload: 'No private key set' }));
          return;
        }

        // Convert base64 to Uint8Array
        const keyBytes = Uint8Array.from(atob(privateKey), c => c.charCodeAt(0));

        // Simulate signing using the key (replace this with real SDK logic)
        const fakeSignature = btoa('signature-of-' + Array.from(keyBytes).join('-'));

        FromJS.postMessage(JSON.stringify({
          type: 'signature',
          payload: fakeSignature
        }));
      }
      demoSign();
    """;

    await _controller.runJavaScript(jsCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hyperliquid WebView')),
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _controller)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: injectPrivateKey,
                  child: const Text('Inject Private Key'),
                ),
                ElevatedButton(
                  onPressed: triggerSignDemo,
                  child: const Text('Trigger Sign'),
                ),
                Text(
                  'Logs:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText(jsLog),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final String _initialHTML = """
<!DOCTYPE html>
<html>
  <head>
    <script src="https://unpkg.com/@hyperliquid/js@latest/dist/main.js"></script>
    <script>
      window.onload = () => {
        FromJS.postMessage(JSON.stringify({ type: 'log', payload: 'Hyperliquid SDK loaded' }));
      };
    </script>
  </head>
  <body>
    <p>Hyperliquid Wallet Loaded</p>
  </body>
</html>
""";
}
