# crypto_wallet

A new Flutter project.

This app simulates a non-custodial crypto wallet that:

1. Generates an Ed25519 key pair.
2. Encrypts the private key using AES-GCM with a password. 3. Stores the encrypted key in secure local storage (flutter_secure_storage). 4. Decrypts the key when the correct password is entered. 5. Displays each step of encryption and decryption in the UI for educational clarity.

Ed25519: A secure elliptic curve digital signature algorithm. Used for signing transactions.
AES-GCM: Symmetric encryption algorithm with built-in integrity check (MAC).
Base64: Converts binary data into readable strings for JSON/storage.
flutter_secure_storage: Stores sensitive data securely using Keychain (iOS) / Keystore (Android).
StringBuffer: Efficient way to build strings step-by-step, used for displaying logs.

Base64 is a way to convert binary data (like bytes from an encryption key, file, or image) into a text format using only printable ASCII characters.
• Binary data → Encoded into 64-character-safe text
• Result: You can safely store or transmit the data as a string (e.g., in JSON, databases, HTTP headers)

When you encrypt data like a private key using AES-GCM, the output is raw bytes (Uint8List), which:
1 Can’t be stored directly in things like:
• Secure storage (which expects string values)
• JSON objects (which don’t support binary)
2 May break APIs or files if not encoded
