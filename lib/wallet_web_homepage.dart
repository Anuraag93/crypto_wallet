import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('signWithPrivateKey')
external Object signWithPrivateKey(String base64Key, String orderJson);

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  final storage = FlutterSecureStorage();
  final passwordController = TextEditingController();
  SimpleKeyPair? keyPair;
  String? publicKeyBase64;
  String? privateKeyBase64;
  String encryptionSteps = '';
  String decryptionSteps = '';
  String? signedOrder;

  @override
  void dispose() {
    passwordController.clear();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> generateAndStoreKeyPair(String password) async {
    final buffer = StringBuffer();
    final algorithm = Ed25519();
    final pair = await algorithm.newKeyPair();
    final privateKeyBytes = await pair.extractPrivateKeyBytes();

    buffer.writeln(
      '1. Generated Private Key Bytes:\n${privateKeyBytes.toString()}\n',
    );

    final aesAlgorithm = AesGcm.with256bits();
    final secretKey = SecretKey(utf8.encode(password.padRight(32, '0')));
    final nonce = aesAlgorithm.newNonce();

    buffer.writeln('2. Generated Nonce (raw bytes):\n$nonce\n');

    final encrypted = await aesAlgorithm.encrypt(
      privateKeyBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    final encryptedPackage = jsonEncode({
      'cipherText': base64Encode(encrypted.cipherText),
      'nonce': base64Encode(encrypted.nonce),
      'mac': base64Encode(encrypted.mac.bytes),
    });

    buffer.writeln(
      '3. CipherText (Base64):\n${base64Encode(encrypted.cipherText)}',
    );
    buffer.writeln('4. Nonce (Base64):\n${base64Encode(encrypted.nonce)}');
    buffer.writeln('5. MAC (Base64):\n${base64Encode(encrypted.mac.bytes)}');

    encryptionSteps = buffer.toString();
    await storage.write(key: 'encryptedPrivateKey', value: encryptedPackage);

    final publicKey = await pair.extractPublicKey();
    setState(() {
      keyPair = pair;
      publicKeyBase64 = base64Encode(publicKey.bytes);
      privateKeyBase64 = base64Encode(privateKeyBytes);
    });
  }

  Future<void> unlockWallet(String password) async {
    final buffer = StringBuffer();
    final encryptedPackage = await storage.read(key: 'encryptedPrivateKey');
    if (encryptedPackage == null) return;

    final decoded = jsonDecode(encryptedPackage);
    final cipherText = base64Decode(decoded['cipherText']);
    final nonce = base64Decode(decoded['nonce']);
    final mac = Mac(base64Decode(decoded['mac']));

    buffer.writeln('1. Retrieved and Decoded CipherText: \n$cipherText\n');
    buffer.writeln('2. Retrieved and Decoded Nonce: \n$nonce\n');
    buffer.writeln('3. Retrieved and Decoded MAC: \n${mac.bytes}\n');

    final aesAlgorithm = AesGcm.with256bits();
    final secretKey = SecretKey(utf8.encode(password.padRight(32, '0')));

    try {
      final decrypted = await aesAlgorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: secretKey,
      );

      buffer.writeln(
        '4. Decrypted Private Key Bytes: \n${decrypted.toString()}\n',
      );

      final algorithm = Ed25519();
      final restoredKeyPair = await algorithm.newKeyPairFromSeed(decrypted);
      final publicKey = await restoredKeyPair.extractPublicKey();

      setState(() {
        keyPair = restoredKeyPair;
        publicKeyBase64 = base64Encode(publicKey.bytes);
        privateKeyBase64 = base64Encode(decrypted);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid password or decryption error')),
      );
    }

    decryptionSteps = buffer.toString();
  }

  Future<void> signOrderWithJS() async {
    if (privateKeyBase64 == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unlock wallet first')));
      return;
    }

    final order = {
      "type": "order",
      "coin": "ETH",
      "isBuy": true,
      "sz": 0.01,
      "limitPx": 3000,
      "orderType": "limit",
      "clientOrderId": "web-interop-demo-1",
    };

    final orderJson = jsonEncode(order);

    try {
      final result = await promiseToFuture<String>(
        signWithPrivateKey(privateKeyBase64!, orderJson),
      );

      setState(() {
        signedOrder = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('JS signing error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crypto Wallet Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Enter PIN or Password'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () =>
                    generateAndStoreKeyPair(passwordController.text),
                child: Text('Generate & Store Key'),
              ),
              ElevatedButton(
                onPressed: () => unlockWallet(passwordController.text),
                child: Text('Unlock Wallet'),
              ),
              ElevatedButton(
                onPressed: signOrderWithJS,
                child: Text('Sign Sample Order (JS)'),
              ),
              SizedBox(height: 20),
              if (publicKeyBase64 != null)
                SelectableText('Public Key (Base64):\n$publicKeyBase64'),
              SizedBox(height: 20),
              if (encryptionSteps.isNotEmpty)
                Text(
                  'Encryption Steps:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              if (encryptionSteps.isNotEmpty) SelectableText(encryptionSteps),
              SizedBox(height: 20),
              if (decryptionSteps.isNotEmpty)
                Text(
                  'Decryption Steps:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              if (decryptionSteps.isNotEmpty) SelectableText(decryptionSteps),
              SizedBox(height: 20),
              if (signedOrder != null)
                SelectableText('Signed Order (Base64):\n$signedOrder'),
            ],
          ),
        ),
      ),
    );
  }
}
