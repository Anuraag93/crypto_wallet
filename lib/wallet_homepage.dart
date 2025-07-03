import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';

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

  Future<void> generateAndStoreKeyPair(String password) async {
    final algorithm = Ed25519();
    final pair = await algorithm.newKeyPair();
    final privateKeyBytes = await pair.extractPrivateKeyBytes();

    final aesAlgorithm = AesGcm.with256bits();
    final secretKey = SecretKey(utf8.encode(password.padRight(32, '0')));
    final nonce = aesAlgorithm.newNonce();

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

    await storage.write(key: 'encryptedPrivateKey', value: encryptedPackage);

    // await storage.write(
    //   key: 'encryptedPrivateKey',
    //   value: base64Encode(encrypted.concatenation()),
    // );
    // await storage.write(key: 'nonce', value: base64Encode(nonce));

    final publicKey = await pair.extractPublicKey();
    setState(() {
      keyPair = pair;
      publicKeyBase64 = base64Encode(publicKey.bytes);
    });
  }

  Future<void> unlockWallet(String password) async {
    final encryptedPackage = await storage.read(key: 'encryptedPrivateKey');
    if (encryptedPackage == null) return;

    final decoded = jsonDecode(encryptedPackage);
    final cipherText = base64Decode(decoded['cipherText']);
    final nonce = base64Decode(decoded['nonce']);
    final mac = Mac(base64Decode(decoded['mac']));

    final aesAlgorithm = AesGcm.with256bits();
    final secretKey = SecretKey(utf8.encode(password.padRight(32, '0')));

    try {
      final decrypted = await aesAlgorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: secretKey,
      );
      final algorithm = Ed25519();
      final restoredKeyPair = await algorithm.newKeyPairFromSeed(decrypted);
      final publicKey = await restoredKeyPair.extractPublicKey();
      setState(() {
        keyPair = restoredKeyPair;
        publicKeyBase64 = base64Encode(publicKey.bytes);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid password or decryption error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crypto Wallet Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Enter PIN or Password'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => generateAndStoreKeyPair(passwordController.text),
              child: Text('Generate & Store Key'),
            ),
            ElevatedButton(
              onPressed: () => unlockWallet(passwordController.text),
              child: Text('Unlock Wallet'),
            ),
            SizedBox(height: 20),
            if (publicKeyBase64 != null)
              SelectableText('Public Key (Base64):\n$publicKeyBase64'),
          ],
        ),
      ),
    );
  }
}
