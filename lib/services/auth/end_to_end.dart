import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static String encrypt(String data, String key) {
    final keyBytes = utf8.encode(key);
    final plainText = utf8.encode(data);
    final cipher = Hmac(sha256, keyBytes);
    final encryptedBytes = cipher.convert(plainText).bytes;

    return base64.encode(encryptedBytes);
  }

  static String decrypt(String encryptedData, String key) {
    final keyBytes = utf8.encode(key);
    final encryptedBytes = base64.decode(encryptedData);
    final cipher = Hmac(sha256, keyBytes);
    final decryptedBytes = cipher.convert(encryptedBytes).bytes;

    return utf8.decode(decryptedBytes);
  }
}
