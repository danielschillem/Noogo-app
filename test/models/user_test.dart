import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/models/user.dart';

void main() {
  group('User.fromJson', () {
    test('parse un utilisateur complet', () {
      final json = {
        'id': 7,
        'name': 'Moussa Traoré',
        'phone': '+22670000001',
        'email': 'moussa@example.com',
        'created_at': '2026-03-15T10:00:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.id, '7');
      expect(user.name, 'Moussa Traoré');
      expect(user.phone, '+22670000001');
      expect(user.email, 'moussa@example.com');
      expect(user.createdAt, isNotNull);
      expect(user.createdAt!.year, 2026);
    });

    test('accepte "nom" comme clé alternative pour name', () {
      final json = {
        'id': 1,
        'nom': 'Fatima B.',
        'telephone': '+22675000002',
      };

      final user = User.fromJson(json);
      expect(user.name, 'Fatima B.');
      expect(user.phone, '+22675000002');
    });

    test('accepte "telephone" comme clé alternative pour phone', () {
      final json = {
        'id': 2,
        'name': 'Jean D.',
        'telephone': '0000002',
      };

      final user = User.fromJson(json);
      expect(user.phone, '0000002');
    });

    test('id null si clé id absente', () {
      final json = {
        'name': 'Sans ID',
        'phone': '0000000',
      };

      final user = User.fromJson(json);
      expect(user.id, isNull);
    });

    test('email null si absent', () {
      final json = {
        'id': 3,
        'name': 'Test',
        'phone': '0000003',
      };

      final user = User.fromJson(json);
      expect(user.email, isNull);
    });

    test('createdAt null si absent', () {
      final json = {
        'id': 4,
        'name': 'Test',
        'phone': '0000004',
      };

      final user = User.fromJson(json);
      expect(user.createdAt, isNull);
    });

    test('createdAt null si date invalide', () {
      final json = {
        'id': 5,
        'name': 'Test',
        'phone': '0000005',
        'created_at': 'not-a-date',
      };

      final user = User.fromJson(json);
      expect(user.createdAt, isNull);
    });

    test('id converti en string depuis int', () {
      final json = {'id': 42, 'name': 'Test', 'phone': '0'};
      final user = User.fromJson(json);
      expect(user.id, '42');
    });
  });

  group('User.toJson', () {
    test('convertit correctement en JSON', () {
      final user = User(
        id: '10',
        name: 'Ali K.',
        phone: '+22660000001',
        email: 'ali@example.com',
        createdAt: DateTime(2026, 4, 1),
      );

      final json = user.toJson();
      expect(json['id'], '10');
      expect(json['name'], 'Ali K.');
      expect(json['telephone'], '+22660000001'); // clé backend
      expect(json['email'], 'ali@example.com');
      expect(json['created_at'], isNotNull);
    });

    test('inclut null pour email si absent', () {
      final user = User(name: 'Test', phone: '0');
      final json = user.toJson();
      expect(json.containsKey('email'), true);
      expect(json['email'], isNull);
    });
  });
}
