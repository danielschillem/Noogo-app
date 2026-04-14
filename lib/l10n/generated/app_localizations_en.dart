// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Noogo';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get error_loading => 'Loading error';

  @override
  String get no_internet => 'Server unreachable — showing local data';

  @override
  String get scan_qr => 'Scan QR Code';

  @override
  String get scan_qr_subtitle => 'Scan the QR code on your table to start';

  @override
  String get menu => 'Menu';

  @override
  String get cart => 'Cart';

  @override
  String get orders => 'Orders';

  @override
  String get profile => 'Profile';

  @override
  String get home => 'Home';

  @override
  String get cart_empty => 'Your cart is empty';

  @override
  String get cart_empty_subtitle =>
      'Add dishes from the menu to start your order';

  @override
  String get see_menu => 'See menu';

  @override
  String get order_type => 'Order type';

  @override
  String get order_type_sur_place => 'Dine in';

  @override
  String get order_type_a_emporter => 'Take away';

  @override
  String get order_type_livraison => 'Delivery';

  @override
  String get payment_method => 'Payment method';

  @override
  String get payment_cash => 'Cash';

  @override
  String get payment_mobile_money => 'Mobile Money';

  @override
  String get table_number => 'Table number';

  @override
  String get table_number_required => 'Table number is required';

  @override
  String get table_number_invalid => 'Invalid format (eg: A1, 12, B-3)';

  @override
  String get phone_number => 'Phone number';

  @override
  String get phone_number_required => 'Phone number is required';

  @override
  String get phone_number_invalid => 'Invalid number (format +226 00 00 00 00)';

  @override
  String get place_order => 'Place order';

  @override
  String get order_confirmed => 'Order confirmed';

  @override
  String get order_preparing => 'Preparing';

  @override
  String get order_ready => 'Order ready!';

  @override
  String get order_delivered => 'Order delivered';

  @override
  String get order_cancelled => 'Order cancelled';

  @override
  String get order_pending => 'Pending';

  @override
  String get order_completed => 'Order completed';

  @override
  String get total => 'Total';

  @override
  String total_amount(String amount) {
    return '$amount FCFA';
  }

  @override
  String get categories => 'Categories';

  @override
  String get all_dishes => 'All dishes';

  @override
  String get favorites => 'Favorites';

  @override
  String get dish_of_the_day => 'Dish of the day';

  @override
  String get add_to_cart => 'Add to cart';

  @override
  String get notifications => 'Notifications';

  @override
  String get no_notifications => 'No notifications';

  @override
  String get mark_all_read => 'Mark all as read';

  @override
  String get restaurant_closed => 'Restaurant closed';

  @override
  String get restaurant_open => 'Open';

  @override
  String get rate_order => 'Rate order';

  @override
  String get rating_title => 'Your feedback';

  @override
  String get rating_subtitle => 'How was your order?';

  @override
  String get rating_comment_hint => 'Comment (optional)...';

  @override
  String get submit => 'Submit';

  @override
  String get cancel => 'Cancel';

  @override
  String get login => 'Log in';

  @override
  String get logout => 'Log out';

  @override
  String get sign_up => 'Create account';

  @override
  String get guest_mode => 'Continue as guest';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get no_orders => 'No orders';

  @override
  String get no_orders_subtitle => 'Your orders will appear here';

  @override
  String preparation_time(int minutes) {
    return '$minutes min';
  }

  @override
  String items_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }
}
