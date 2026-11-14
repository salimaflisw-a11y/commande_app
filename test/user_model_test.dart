import 'package:flutter_test/flutter_test.dart';
import 'package:commande_app/models/user_model.dart';

void main() {
  group('UserModel tests', () {
    test('tolerant fromJson with only required fields (admin)', () {
      final json = {
        'id': 'admin_uid_123',
        'email': 'admin@gmail.com',
        'role': 'admin',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'admin_uid_123');
      expect(user.email, 'admin@gmail.com');
      expect(user.role, 'admin');
      expect(user.name, '');
      expect(user.phone, '');
      expect(user.createdAt, isNotNull);
    });

    test('role defaults to client if missing', () {
      final json = {
        'id': 'client_uid_456',
        'email': 'client@gmail.com',
      };

      final user = UserModel.fromJson(json);

      expect(user.role, 'client');
      expect(user.name, '');
      expect(user.phone, '');
    });

    test('createdAt parses ISO string and falls back to now on invalid or missing', () {
      final validJson = {
        'id': '1',
        'email': 'a@b.com',
        'role': 'client',
        'createdAt': '2025-01-15T10:30:00.000Z',
      };
      final userValid = UserModel.fromJson(validJson);
      expect(userValid.createdAt, DateTime.parse('2025-01-15T10:30:00.000Z'));

      final invalidJson = {
        'id': '2',
        'email': 'c@d.com',
        'role': 'client',
        'createdAt': 'invalid-date-string',
      };
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final userInvalid = UserModel.fromJson(invalidJson);
      expect(userInvalid.createdAt.isAfter(before), isTrue);
    });

    test('tolerant parsing prevents throwing on unexpected types', () {
      final json = {
        'id': 12345, // int instead of string
        'name': null,
        'email': 'mixed@test.com',
        'phone': 612345678,
        'role': null,
        'createdAt': null,
      };

      final user = UserModel.fromJson(json);
      expect(user.id, '12345');
      expect(user.name, '');
      expect(user.email, 'mixed@test.com');
      expect(user.phone, '612345678');
      expect(user.role, 'client');
      expect(user.createdAt, isNotNull);
    });

    test('toJson produces correct structure without address', () {
      final user = UserModel(
        id: 'u1',
        name: 'Test Name',
        email: 'test@example.com',
        phone: '12345678',
        role: 'client',
        createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
      );

      final map = user.toJson();
      expect(map.containsKey('address'), isFalse);
      expect(map['id'], 'u1');
      expect(map['name'], 'Test Name');
      expect(map['email'], 'test@example.com');
      expect(map['phone'], '12345678');
      expect(map['role'], 'client');
      expect(map['createdAt'], '2025-01-01T00:00:00.000Z');
    });
  });
}
