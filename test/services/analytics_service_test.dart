import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noogo/services/analytics_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      dotenv.loadFromString(envString: 'ENVIRONMENT=test');
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Toutes les méthodes analytics sont statiques et ne plantent pas
  // même sans endpoint configuré (analyticsEndpoint vide en test).

  group('AnalyticsService — méthodes QR', () {
    test('qrScanned ne plante pas', () async {
      await expectLater(
        AnalyticsService.qrScanned(1),
        completes,
      );
    });

    test('qrValidated ne plante pas', () async {
      await expectLater(
        AnalyticsService.qrValidated(1, 'Le Baobab'),
        completes,
      );
    });
  });

  group('AnalyticsService — méthodes menu', () {
    test('dishAddedToCart ne plante pas', () async {
      await expectLater(
        AnalyticsService.dishAddedToCart(
          dishId: 1,
          dishName: 'Riz',
          price: 1500,
          restaurantId: 1,
        ),
        completes,
      );
    });

    test('dishRemovedFromCart ne plante pas', () async {
      await expectLater(
        AnalyticsService.dishRemovedFromCart(1),
        completes,
      );
    });

    test('dishFavoriteToggled true ne plante pas', () async {
      await expectLater(
        AnalyticsService.dishFavoriteToggled(1, true),
        completes,
      );
    });

    test('dishFavoriteToggled false ne plante pas', () async {
      await expectLater(
        AnalyticsService.dishFavoriteToggled(1, false),
        completes,
      );
    });
  });

  group('AnalyticsService — méthodes commande', () {
    test('orderPlaced ne plante pas', () async {
      await expectLater(
        AnalyticsService.orderPlaced(
          orderId: 42,
          totalAmount: 3000,
          orderType: 'sur place',
          paymentMethod: 'cash',
          restaurantId: 1,
          itemCount: 2,
        ),
        completes,
      );
    });

    test('orderCancelled ne plante pas', () async {
      await expectLater(
        AnalyticsService.orderCancelled(42),
        completes,
      );
    });

    test('orderRated ne plante pas', () async {
      await expectLater(
        AnalyticsService.orderRated(42, 5),
        completes,
      );
    });
  });

  group('AnalyticsService — méthodes paiement', () {
    test('paymentInitiated ne plante pas', () async {
      await expectLater(
        AnalyticsService.paymentInitiated(
          method: 'orange',
          amount: 1500,
        ),
        completes,
      );
    });

    test('paymentSuccess ne plante pas', () async {
      await expectLater(
        AnalyticsService.paymentSuccess('orange', 1500),
        completes,
      );
    });

    test('paymentFailed ne plante pas', () async {
      await expectLater(
        AnalyticsService.paymentFailed('orange', 'Timeout'),
        completes,
      );
    });
  });

  group('AnalyticsService — méthodes navigation/user', () {
    test('screenViewed ne plante pas', () async {
      await expectLater(
        AnalyticsService.screenViewed('HomeScreen'),
        completes,
      );
    });

    test('userLoggedIn ne plante pas', () async {
      await expectLater(
        AnalyticsService.userLoggedIn('phone'),
        completes,
      );
    });

    test('guestModeEntered ne plante pas', () async {
      await expectLater(
        AnalyticsService.guestModeEntered(),
        completes,
      );
    });

    test('userLoggedOut ne plante pas', () async {
      await expectLater(
        AnalyticsService.userLoggedOut(),
        completes,
      );
    });
  });
}
