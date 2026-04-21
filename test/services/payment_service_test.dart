import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noogo/services/payment_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      dotenv.loadFromString(envString: 'ENVIRONMENT=test');
    } catch (_) {}
  });

  // ── PaymentStatus enum ─────────────────────────────────────────────────────

  group('PaymentStatus', () {
    test('a 6 valeurs', () {
      expect(PaymentStatus.values.length, 6);
    });
  });

  // ── PaymentStatusX.fromString ──────────────────────────────────────────────

  group('PaymentStatusX.fromString', () {
    test('pending', () {
      expect(PaymentStatusX.fromString('pending'), PaymentStatus.pending);
    });

    test('processing', () {
      expect(PaymentStatusX.fromString('processing'), PaymentStatus.processing);
    });

    test('completed', () {
      expect(PaymentStatusX.fromString('completed'), PaymentStatus.completed);
    });

    test('failed', () {
      expect(PaymentStatusX.fromString('failed'), PaymentStatus.failed);
    });

    test('expired', () {
      expect(PaymentStatusX.fromString('expired'), PaymentStatus.expired);
    });

    test('cancelled', () {
      expect(PaymentStatusX.fromString('cancelled'), PaymentStatus.cancelled);
    });

    test('inconnu retourne pending par défaut', () {
      expect(PaymentStatusX.fromString('unknown_xyz'), PaymentStatus.pending);
    });
  });

  // ── PaymentStatusX.isActive ────────────────────────────────────────────────

  group('PaymentStatusX.isActive', () {
    test('pending est actif', () {
      expect(PaymentStatus.pending.isActive, isTrue);
    });

    test('processing est actif', () {
      expect(PaymentStatus.processing.isActive, isTrue);
    });

    test('completed n\'est pas actif', () {
      expect(PaymentStatus.completed.isActive, isFalse);
    });

    test('failed n\'est pas actif', () {
      expect(PaymentStatus.failed.isActive, isFalse);
    });

    test('expired n\'est pas actif', () {
      expect(PaymentStatus.expired.isActive, isFalse);
    });

    test('cancelled n\'est pas actif', () {
      expect(PaymentStatus.cancelled.isActive, isFalse);
    });
  });

  // ── PaymentStatusX.isCompleted ─────────────────────────────────────────────

  group('PaymentStatusX.isCompleted', () {
    test('completed est vrai', () {
      expect(PaymentStatus.completed.isCompleted, isTrue);
    });

    test('pending n\'est pas completed', () {
      expect(PaymentStatus.pending.isCompleted, isFalse);
    });

    test('failed n\'est pas completed', () {
      expect(PaymentStatus.failed.isCompleted, isFalse);
    });
  });

  // ── PaymentStatusX.isFailed ───────────────────────────────────────────────

  group('PaymentStatusX.isFailed', () {
    test('failed est échoué', () {
      expect(PaymentStatus.failed.isFailed, isTrue);
    });

    test('expired est échoué', () {
      expect(PaymentStatus.expired.isFailed, isTrue);
    });

    test('cancelled est échoué', () {
      expect(PaymentStatus.cancelled.isFailed, isTrue);
    });

    test('pending n\'est pas échoué', () {
      expect(PaymentStatus.pending.isFailed, isFalse);
    });

    test('completed n\'est pas échoué', () {
      expect(PaymentStatus.completed.isFailed, isFalse);
    });
  });

  // ── PaymentRecord.fromJson ─────────────────────────────────────────────────

  group('PaymentRecord.fromJson', () {
    final baseJson = {
      'id': 42,
      'reference': 'PAY-2024-001',
      'status': 'pending',
      'provider': 'orange',
      'phone': '70000000',
      'amount': 5000,
    };

    test('crée un PaymentRecord depuis JSON complet', () {
      final record = PaymentRecord.fromJson(baseJson);
      expect(record.id, 42);
      expect(record.reference, 'PAY-2024-001');
      expect(record.status, PaymentStatus.pending);
      expect(record.provider, 'orange');
      expect(record.phone, '70000000');
      expect(record.amount, 5000);
    });

    test('operatorTransactionId est null si absent', () {
      final record = PaymentRecord.fromJson(baseJson);
      expect(record.operatorTransactionId, isNull);
    });

    test('operatorTransactionId est renseigné si présent', () {
      final json = {...baseJson, 'operator_transaction_id': 'TXN-999'};
      final record = PaymentRecord.fromJson(json);
      expect(record.operatorTransactionId, 'TXN-999');
    });

    test('confirmedAt parsé depuis ISO 8601', () {
      final json = {
        ...baseJson,
        'confirmed_at': '2024-01-15T12:30:00.000Z',
      };
      final record = PaymentRecord.fromJson(json);
      expect(record.confirmedAt, isNotNull);
      expect(record.confirmedAt!.year, 2024);
    });

    test('confirmedAt est null si absent', () {
      final record = PaymentRecord.fromJson(baseJson);
      expect(record.confirmedAt, isNull);
    });

    test('expiresAt parsé depuis ISO 8601', () {
      final json = {
        ...baseJson,
        'expires_at': '2024-01-15T13:00:00.000Z',
      };
      final record = PaymentRecord.fromJson(json);
      expect(record.expiresAt, isNotNull);
    });

    test('status completed reconnu', () {
      final json = {...baseJson, 'status': 'completed'};
      final record = PaymentRecord.fromJson(json);
      expect(record.status, PaymentStatus.completed);
    });

    test('status cancelled reconnu', () {
      final json = {...baseJson, 'status': 'cancelled'};
      final record = PaymentRecord.fromJson(json);
      expect(record.status, PaymentStatus.cancelled);
    });

    test('amount peut être un double converti en int', () {
      final json = {...baseJson, 'amount': 7500.0};
      final record = PaymentRecord.fromJson(json);
      expect(record.amount, 7500);
    });
  });

  // ── PaymentResult ─────────────────────────────────────────────────────────

  group('PaymentResult', () {
    test('ok() crée un résultat succès', () {
      final r = PaymentResult.ok();
      expect(r.success, isTrue);
      expect(r.errorMessage, isNull);
    });

    test('fail() crée un résultat échec avec message', () {
      final r = PaymentResult.fail('Solde insuffisant');
      expect(r.success, isFalse);
      expect(r.errorMessage, 'Solde insuffisant');
    });
  });

  // ── PaymentService.providerLabel ──────────────────────────────────────────

  group('PaymentService.providerLabel', () {
    test('orange → Orange Money', () {
      expect(PaymentService.providerLabel('orange'), 'Orange Money');
    });

    test('moov → Moov Africa', () {
      expect(PaymentService.providerLabel('moov'), 'Moov Africa');
    });

    test('wave → Wave', () {
      expect(PaymentService.providerLabel('wave'), 'Wave');
    });

    test('telecel → Telecel Money', () {
      expect(PaymentService.providerLabel('telecel'), 'Telecel Money');
    });

    test('cash → Espèces', () {
      expect(PaymentService.providerLabel('cash'), 'Espèces');
    });

    test('inconnu retourne la valeur brute', () {
      expect(PaymentService.providerLabel('momo'), 'momo');
    });
  });

  // ── PaymentService.providerColorValue ─────────────────────────────────────

  group('PaymentService.providerColorValue', () {
    test('orange → 0xFFFF7900', () {
      expect(PaymentService.providerColorValue('orange'), 0xFFFF7900);
    });

    test('moov → 0xFF003DA5', () {
      expect(PaymentService.providerColorValue('moov'), 0xFF003DA5);
    });

    test('wave → 0xFF1DBFAF', () {
      expect(PaymentService.providerColorValue('wave'), 0xFF1DBFAF);
    });

    test('telecel → 0xFFE30613', () {
      expect(PaymentService.providerColorValue('telecel'), 0xFFE30613);
    });

    test('cash → 0xFF4CAF50', () {
      expect(PaymentService.providerColorValue('cash'), 0xFF4CAF50);
    });

    test('inconnu → 0xFF9E9E9E', () {
      expect(PaymentService.providerColorValue('unknown'), 0xFF9E9E9E);
    });
  });

  // ── PaymentService.initiate (erreur réseau) ───────────────────────────────

  group('PaymentService.initiate (erreur réseau)', () {
    test('retourne success:false si réseau inaccessible', () async {
      final result = await PaymentService.initiate(
        restaurantId: 1,
        provider: 'orange',
        phone: '70000000',
        amount: 5000,
      );
      expect(result.success, isFalse);
      expect(result.message, isNotEmpty);
    });
  });

  // ── PaymentService.cancel (erreur réseau) ─────────────────────────────────

  group('PaymentService.cancel (erreur réseau)', () {
    test('retourne false si réseau inaccessible', () async {
      final ok = await PaymentService.cancel(999);
      expect(ok, isFalse);
    });
  });

  // ── PaymentService.checkStatus (erreur réseau) ────────────────────────────

  group('PaymentService.checkStatus (erreur réseau)', () {
    test('retourne null si réseau inaccessible', () async {
      final record = await PaymentService.checkStatus(999);
      expect(record, isNull);
    });
  });

  // ── PaymentInitResult ─────────────────────────────────────────────────────

  group('PaymentInitResult', () {
    test('crée un résultat success avec mode simulation', () {
      final r = PaymentInitResult(
        success: true,
        message: 'OK',
        mode: 'simulation',
      );
      expect(r.success, isTrue);
      expect(r.payment, isNull);
      expect(r.mode, 'simulation');
    });

    test('crée un résultat échec', () {
      final r = PaymentInitResult(
        success: false,
        message: 'Erreur paiement',
      );
      expect(r.success, isFalse);
    });
  });
}
