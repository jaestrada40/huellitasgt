import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSecretStore implements SecretStore {
  const SecureSecretStore([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class PinStore {
  PinStore(this._secrets);
  final SecretStore _secrets;

  static final _fourDigits = RegExp(r'^\d{4}$');

  Future<bool> get hasPin async => (await _secrets.read('pin_hash')) != null;

  Future<void> setPin(String pin) async {
    if (!_fourDigits.hasMatch(pin)) {
      throw ArgumentError.value(pin, 'pin', 'debe tener 4 dígitos');
    }
    final salt = _newSalt();
    await _secrets.write('pin_salt', salt);
    await _secrets.write('pin_hash', _hash(salt, pin));
  }

  Future<bool> verify(String pin) async {
    final salt = await _secrets.read('pin_salt');
    final hash = await _secrets.read('pin_hash');
    if (salt == null || hash == null) return false;
    return _hash(salt, pin) == hash;
  }

  Future<void> clear() async {
    await _secrets.delete('pin_salt');
    await _secrets.delete('pin_hash');
  }

  static String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static String _newSalt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }
}
