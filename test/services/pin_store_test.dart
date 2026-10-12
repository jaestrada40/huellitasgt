import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/services/pin_store.dart';

class InMemorySecretStore implements SecretStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  late InMemorySecretStore secrets;
  late PinStore pin;
  setUp(() {
    secrets = InMemorySecretStore();
    pin = PinStore(secrets);
  });

  test('sin PIN configurado: hasPin falso y verify falso', () async {
    expect(await pin.hasPin, isFalse);
    expect(await pin.verify('1234'), isFalse);
  });

  test('setPin y verify', () async {
    await pin.setPin('4821');
    expect(await pin.hasPin, isTrue);
    expect(await pin.verify('4821'), isTrue);
    expect(await pin.verify('4822'), isFalse);
  });

  test('no guarda el PIN en claro', () async {
    await pin.setPin('4821');
    expect(secrets.data.values.any((v) => v.contains('4821')), isFalse);
  });

  test('rechaza PIN que no sea de 4 dígitos', () {
    for (final bad in ['123', '12345', 'abcd', '12 4', '']) {
      expect(() => pin.setPin(bad), throwsArgumentError, reason: bad);
    }
  });

  test('clear elimina el PIN', () async {
    await pin.setPin('4821');
    await pin.clear();
    expect(await pin.hasPin, isFalse);
  });
}
