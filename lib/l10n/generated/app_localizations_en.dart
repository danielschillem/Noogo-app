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

  @override
  String get delivery_address => 'Delivery address';

  @override
  String get delivery_address_hint =>
      'e.g. Zogona district, Street 15.32, Door 45';

  @override
  String get delivery_address_required =>
      'Please enter a valid address (min. 5 characters)';

  @override
  String get delivery_subtitle => 'Get delivered to your door';

  @override
  String get change_password => 'Change password';

  @override
  String get current_password => 'Current password';

  @override
  String get new_password => 'New password';

  @override
  String get confirm_password => 'Confirm password';

  @override
  String get password_changed => 'Password changed successfully';

  @override
  String get password_min_length => 'Minimum 6 characters';

  @override
  String get password_mismatch => 'Passwords do not match';

  @override
  String get my_restaurants => 'My saved restaurants';

  @override
  String get personal_info => 'My personal information';

  @override
  String get delivery_addresses => 'Delivery addresses';

  @override
  String get payment_methods => 'Payment methods';

  @override
  String get order_history => 'Order history';

  @override
  String get notification_settings => 'Notifications';

  @override
  String get help_support => 'Help & support';

  @override
  String get about => 'About';

  @override
  String get dark_mode => 'Dark mode';

  @override
  String get edit_profile => 'Edit profile';

  @override
  String get confirm_order => 'Confirm order';

  @override
  String get empty_cart => 'Your cart is empty';

  @override
  String get clear_cart => 'Clear cart';

  @override
  String get order_success => 'Order sent successfully!';

  @override
  String get order_error => 'Error sending order';

  @override
  String get track_order => 'Track order';

  @override
  String get reorder => 'Reorder';

  @override
  String get rated => 'Rated';

  @override
  String get rate => 'Rate';

  @override
  String get thank_you_rating => 'Thank you for your feedback!';

  @override
  String order_number(int id) {
    return 'Order #$id';
  }

  @override
  String order_count(int count) {
    return '$count order(s)';
  }

  @override
  String get my_orders => 'My Orders';

  @override
  String get close => 'Close';

  @override
  String get modify => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get return_back => 'Back';

  @override
  String get validate => 'Validate';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get search => 'Search';

  @override
  String get search_dishes => 'Search a dish…';

  @override
  String get popular_dishes => 'Popular dishes';

  @override
  String get see_all => 'See all';

  @override
  String get quick_order => 'Quick order';

  @override
  String get offline_mode => 'Offline mode';

  @override
  String get offline_subtitle => 'Limited connection — showing local data';

  @override
  String get connection_error => 'Connection error';

  @override
  String get scan_qr_manual => 'Enter code manually';

  @override
  String get welcome_title => 'Welcome to Noogo';

  @override
  String get create_account => 'Create your NOOGO account';

  @override
  String get connect_benefits =>
      'Log in to access your profile, track your orders and enjoy exclusive benefits.';

  @override
  String get sign_in_up => 'Sign in / Sign up';

  @override
  String get continue_without_account => 'Continue without account';

  @override
  String get logout_confirm => 'Are you sure you want to log out?';

  @override
  String get logout_success => 'Logged out successfully';

  @override
  String get login_success => 'Logged in successfully!';

  @override
  String get profile_updated => 'Profile updated successfully';

  @override
  String get guest_mode_enabled => 'Guest mode enabled';

  @override
  String get added_to_cart => 'Added to cart';

  @override
  String get items_added_to_cart => 'Items added to cart';

  @override
  String get order_cancelled_success => 'Order cancelled successfully!';

  @override
  String get cancel_order => 'Cancel order';

  @override
  String cancel_order_confirm(int id) {
    return 'Do you really want to cancel order #$id?';
  }

  @override
  String get discover_menu => 'Discover the menu';

  @override
  String get change_restaurant => 'Change restaurant';

  @override
  String get full_name => 'Full name';

  @override
  String get phone => 'Phone';

  @override
  String get member_since => 'Member since';

  @override
  String get my_stats => 'My statistics';

  @override
  String get points => 'Points';

  @override
  String get no_address_saved => 'No address saved';

  @override
  String get new_address => 'New address...';

  @override
  String get order_updates => 'Order updates';

  @override
  String get order_updates_subtitle => 'Real-time order status updates';

  @override
  String get promotions => 'Promotions';

  @override
  String get promotions_subtitle => 'Deals and discounts';

  @override
  String get delivery_alerts => 'Delivery alerts';

  @override
  String get delivery_alerts_subtitle => 'Driver location and arrival';

  @override
  String get about_version => 'NOOGO v1.4.0';

  @override
  String get about_description => 'Restaurant ordering app';

  @override
  String get about_copyright => '© 2026 Quick dev-it. All rights reserved.';

  @override
  String get forgot_password => 'Forgot password?';

  @override
  String get reset_password => 'Reset password';

  @override
  String get name_required => 'Please enter your name';

  @override
  String get enter_name => 'Enter your name';

  @override
  String get enter_phone => 'Phone number';

  @override
  String get enter_email => 'Email (optional)';

  @override
  String get enter_password => 'Password';

  @override
  String get order_summary => 'Summary';

  @override
  String get delivery_fee => 'Delivery fee';

  @override
  String get subtotal => 'Subtotal';
}
