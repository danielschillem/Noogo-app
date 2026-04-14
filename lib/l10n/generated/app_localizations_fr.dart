// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Noogo';

  @override
  String get loading => 'Chargement...';

  @override
  String get retry => 'Réessayer';

  @override
  String get error_loading => 'Erreur de chargement';

  @override
  String get no_internet =>
      'Connexion au serveur impossible — affichage des données locales';

  @override
  String get scan_qr => 'Scanner le QR Code';

  @override
  String get scan_qr_subtitle =>
      'Scannez le QR code de votre table pour commencer';

  @override
  String get menu => 'Menu';

  @override
  String get cart => 'Panier';

  @override
  String get orders => 'Commandes';

  @override
  String get profile => 'Profil';

  @override
  String get home => 'Accueil';

  @override
  String get cart_empty => 'Votre panier est vide';

  @override
  String get cart_empty_subtitle =>
      'Ajoutez des plats depuis le menu pour commencer votre commande';

  @override
  String get see_menu => 'Voir le menu';

  @override
  String get order_type => 'Type de commande';

  @override
  String get order_type_sur_place => 'Sur place';

  @override
  String get order_type_a_emporter => 'À emporter';

  @override
  String get order_type_livraison => 'Livraison';

  @override
  String get payment_method => 'Moyen de paiement';

  @override
  String get payment_cash => 'Espèces';

  @override
  String get payment_mobile_money => 'Mobile Money';

  @override
  String get table_number => 'Numéro de table';

  @override
  String get table_number_required => 'Numéro de table obligatoire';

  @override
  String get table_number_invalid => 'Format invalide (ex: A1, 12, B-3)';

  @override
  String get phone_number => 'Numéro de téléphone';

  @override
  String get phone_number_required => 'Numéro de téléphone obligatoire';

  @override
  String get phone_number_invalid =>
      'Numéro invalide (format +226 00 00 00 00)';

  @override
  String get place_order => 'Commander';

  @override
  String get order_confirmed => 'Commande confirmée';

  @override
  String get order_preparing => 'En préparation';

  @override
  String get order_ready => 'Commande prête !';

  @override
  String get order_delivered => 'Commande livrée';

  @override
  String get order_cancelled => 'Commande annulée';

  @override
  String get order_pending => 'En attente';

  @override
  String get order_completed => 'Commande terminée';

  @override
  String get total => 'Total';

  @override
  String total_amount(String amount) {
    return '$amount FCFA';
  }

  @override
  String get categories => 'Catégories';

  @override
  String get all_dishes => 'Tous les plats';

  @override
  String get favorites => 'Favoris';

  @override
  String get dish_of_the_day => 'Plat du jour';

  @override
  String get add_to_cart => 'Ajouter au panier';

  @override
  String get notifications => 'Notifications';

  @override
  String get no_notifications => 'Aucune notification';

  @override
  String get mark_all_read => 'Tout marquer comme lu';

  @override
  String get restaurant_closed => 'Restaurant fermé';

  @override
  String get restaurant_open => 'Ouvert';

  @override
  String get rate_order => 'Noter la commande';

  @override
  String get rating_title => 'Votre avis';

  @override
  String get rating_subtitle => 'Comment s\'est passée votre commande ?';

  @override
  String get rating_comment_hint => 'Commentaire (optionnel)...';

  @override
  String get submit => 'Envoyer';

  @override
  String get cancel => 'Annuler';

  @override
  String get login => 'Connexion';

  @override
  String get logout => 'Déconnexion';

  @override
  String get sign_up => 'Créer un compte';

  @override
  String get guest_mode => 'Continuer en invité';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get no_orders => 'Aucune commande';

  @override
  String get no_orders_subtitle => 'Vos commandes apparaîtront ici';

  @override
  String preparation_time(int minutes) {
    return '$minutes min';
  }

  @override
  String items_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
      zero: 'Aucun article',
    );
    return '$_temp0';
  }
}
