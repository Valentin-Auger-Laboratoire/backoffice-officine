import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Gère le chiffrement/déchiffrement AES-256-CBC des champs sensibles
/// avant écriture dans la base SQFlite locale.
///
/// NOTE ARCHITECTURE :
/// Ce PoC chiffre les champs jugés sensibles au niveau applicatif (clé
/// conservée dans le Keystore/Keychain via flutter_secure_storage).
/// Pour une mise en production conforme aux exigences d'hébergement de
/// données de santé (HDS), il est recommandé de migrer vers
/// `sqflite_sqlcipher` pour un chiffrement de fichier complet (AES-256),
/// en complément (et non en remplacement) du chiffrement applicatif
/// présenté ici.
class CryptoHelper {
  CryptoHelper._internal();
  static final CryptoHelper instance = CryptoHelper._internal();

  static const _secureStorage = FlutterSecureStorage();
  enc.Key? _key;

  Future<enc.Key> _getOrCreateKey() async {
    if (_key != null) return _key!;
    String? stored =
        await _secureStorage.read(key: AppConstants.secureStorageEncryptionKey);
    if (stored == null) {
      final newKey = enc.Key.fromSecureRandom(32);
      stored = base64Encode(newKey.bytes);
      await _secureStorage.write(
        key: AppConstants.secureStorageEncryptionKey,
        value: stored,
      );
    }
    _key = enc.Key(base64Decode(stored));
    return _key!;
  }

  /// Chiffre un champ avec un IV aléatoire de 16 octets, différent à chaque
  /// appel. Format stocké : `<iv base64>:<texte chiffré base64>`.
  Future<String> encryptField(String plainText) async {
    if (plainText.isEmpty) return plainText;
    final key = await _getOrCreateKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  Future<String> decryptField(String storedValue) async {
    if (storedValue.isEmpty) return storedValue;
    final parts = storedValue.split(':');
    if (parts.length != 2) {
      // Donnée non chiffrée (mock/legacy) -> retour brut
      return storedValue;
    }
    try {
      final key = await _getOrCreateKey();
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(parts[1], iv: enc.IV.fromBase64(parts[0]));
    } catch (_) {
      return storedValue;
    }
  }

  /// Hash SHA-256 irréversible (hexadécimal) d'un identifiant de connexion.
  String hashIdentifiant(String identifiant) {
    return sha256.convert(utf8.encode(identifiant)).toString();
  }
}
