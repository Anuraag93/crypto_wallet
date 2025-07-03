import 'package:crypto_wallet/wallet_homepage_output.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CryptoWalletApp());
}

class CryptoWalletApp extends StatelessWidget {
  const CryptoWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: WalletHomePage());
  }
}
