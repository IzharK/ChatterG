import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class CryptoService extends GetxService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _algorithm = X25519();
  final _symmetricAlgorithm = AesGcm.with256bits();

  final String _identityPrivKeyPrefix = 'identity_private_key_';
  final String _identityPubKeyPrefix = 'identity_public_key_';
  final String _sessionKeyPrefix = 'session_key_';

  Future<SimpleKeyPair> generateAndStoreIdentityKeys(String userId) async {
    final keyPair = await _algorithm.newKeyPair();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = publicKey.bytes;

    await _secureStorage.write(
      key: '$_identityPrivKeyPrefix$userId',
      value: base64Encode(privateKeyBytes),
    );

    await _secureStorage.write(
      key: '$_identityPubKeyPrefix$userId',
      value: base64Encode(publicKeyBytes),
    );

    return keyPair;
  }

  Future<SimpleKeyPair?> getIdentityKeyPair(String userId) async {
    final privateKeyBase64 = await _secureStorage.read(
      key: '$_identityPrivKeyPrefix$userId',
    );
    final publicKeyBase64 = await _secureStorage.read(
      key: '$_identityPubKeyPrefix$userId',
    );

    if (privateKeyBase64 != null && publicKeyBase64 != null) {
      try {
        final privateKeyBytes = base64Decode(privateKeyBase64);
        final publicKeyBytes = base64Decode(publicKeyBase64);
        return SimpleKeyPairData(
          privateKeyBytes,
          publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.x25519),
          type: KeyPairType.x25519,
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<SimplePublicKey?> getIdentityPublicKeyFromStorage(
    String userId,
  ) async {
    final publicKeyBase64 = await _secureStorage.read(
      key: '$_identityPubKeyPrefix$userId',
    );
    if (publicKeyBase64 != null) {
      try {
        final publicKeyBytes = base64Decode(publicKeyBase64);
        return SimplePublicKey(publicKeyBytes, type: KeyPairType.x25519);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<Uint8List?> getPublicKeyBytesForUpload(String userId) async {
    final keyPair = await getIdentityKeyPair(userId);
    if (keyPair != null) {
      final pubKey = await keyPair.extractPublicKey();
      return Uint8List.fromList(pubKey.bytes);
    }
    return null;
  }

  Future<SecretKey?> establishAndStoreSessionKey(
    String chatId,
    String ownUserId,
    SimplePublicKey recipientPublicKey,
  ) async {
    final ownKeyPair = await getIdentityKeyPair(ownUserId);
    if (ownKeyPair == null) {
      return null;
    }

    try {
      final sharedSecret = await _algorithm.sharedSecretKey(
        keyPair: ownKeyPair,
        remotePublicKey: recipientPublicKey,
      );

      final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
      final derivedKey = await hkdf.deriveKey(
        secretKey: sharedSecret,
        nonce: utf8.encode(chatId),
      );

      await _storeSessionKey(chatId, derivedKey);
      return derivedKey;
    } catch (e) {
      return null;
    }
  }

  Future<void> _storeSessionKey(String chatId, SecretKey sessionKey) async {
    final keyBytes = await sessionKey.extractBytes();

    await _secureStorage.write(
      key: '$_sessionKeyPrefix$chatId',
      value: base64Encode(keyBytes),
    );
  }

  Future<SecretKey?> getSessionKey(String chatId) async {
    final keyBase64 = await _secureStorage.read(
      key: '$_sessionKeyPrefix$chatId',
    );
    if (keyBase64 != null) {
      try {
        final keyBytes = base64Decode(keyBase64);
        return SecretKey(keyBytes);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<Map<String, String>?> encryptMessage(
    String chatId,
    String plaintext,
  ) async {
    final sessionKey = await getSessionKey(chatId);
    if (sessionKey == null) {
      return null;
    }

    try {
      final nonce = _symmetricAlgorithm.newNonce();

      final secretBox = await _symmetricAlgorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: sessionKey,
        nonce: nonce,
      );

      return {
        'ciphertext': base64Encode(secretBox.cipherText),
        'nonce': base64Encode(nonce),
        'mac': base64Encode(secretBox.mac.bytes),
      };
    } catch (e) {
      return null;
    }
  }

  Future<String?> decryptMessage(
    String chatId,
    String ciphertextBase64,
    String nonceBase64, [
    String? macBase64,
  ]) async {
    final sessionKey = await getSessionKey(chatId);
    if (sessionKey == null) {
      return null;
    }

    try {
      final ciphertext = base64Decode(ciphertextBase64);
      final nonce = base64Decode(nonceBase64);

      Mac mac = Mac.empty;
      if (macBase64 != null && macBase64.isNotEmpty) {
        mac = Mac(base64Decode(macBase64));
      }

      final secretBox = SecretBox(ciphertext, nonce: nonce, mac: mac);

      final decryptedBytes = await _symmetricAlgorithm.decrypt(
        secretBox,
        secretKey: sessionKey,
      );

      return utf8.decode(decryptedBytes);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteSessionKey(String chatId) async {
    final storageKey = '$_sessionKeyPrefix$chatId';
    try {
      await _secureStorage.delete(key: storageKey);
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> clearUserKeys(String userId) async {
    await _secureStorage.delete(key: '$_identityPrivKeyPrefix$userId');
    await _secureStorage.delete(key: '$_identityPubKeyPrefix$userId');
  }
}
