import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en')
  ];

  /// Nom de l'application
  ///
  /// In fr, this message translates to:
  /// **'Noogo'**
  String get appName;

  /// Indicateur de chargement générique
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// Bouton pour réessayer une action
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// Titre d'erreur générique
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get error_loading;

  /// Bannière hors-ligne
  ///
  /// In fr, this message translates to:
  /// **'Connexion au serveur impossible — affichage des données locales'**
  String get no_internet;

  /// Bouton ou titre scan QR
  ///
  /// In fr, this message translates to:
  /// **'Scanner le QR Code'**
  String get scan_qr;

  /// Sous-titre écran QR
  ///
  /// In fr, this message translates to:
  /// **'Scannez le QR code de votre table pour commencer'**
  String get scan_qr_subtitle;

  /// Onglet menu
  ///
  /// In fr, this message translates to:
  /// **'Menu'**
  String get menu;

  /// Onglet panier
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get cart;

  /// Onglet commandes
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get orders;

  /// Onglet profil
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// Onglet accueil
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// Message panier vide
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est vide'**
  String get cart_empty;

  /// Sous-titre panier vide
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des plats depuis le menu pour commencer votre commande'**
  String get cart_empty_subtitle;

  /// Bouton vers le menu
  ///
  /// In fr, this message translates to:
  /// **'Voir le menu'**
  String get see_menu;

  /// Libellé type de commande
  ///
  /// In fr, this message translates to:
  /// **'Type de commande'**
  String get order_type;

  /// Type de commande sur place
  ///
  /// In fr, this message translates to:
  /// **'Sur place'**
  String get order_type_sur_place;

  /// Type de commande à emporter
  ///
  /// In fr, this message translates to:
  /// **'À emporter'**
  String get order_type_a_emporter;

  /// Type de commande livraison
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get order_type_livraison;

  /// Libellé moyen de paiement
  ///
  /// In fr, this message translates to:
  /// **'Moyen de paiement'**
  String get payment_method;

  /// Paiement en espèces
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get payment_cash;

  /// Paiement par Mobile Money
  ///
  /// In fr, this message translates to:
  /// **'Mobile Money'**
  String get payment_mobile_money;

  /// Champ numéro de table
  ///
  /// In fr, this message translates to:
  /// **'Numéro de table'**
  String get table_number;

  /// Erreur champ table vide
  ///
  /// In fr, this message translates to:
  /// **'Numéro de table obligatoire'**
  String get table_number_required;

  /// Erreur format table
  ///
  /// In fr, this message translates to:
  /// **'Format invalide (ex: A1, 12, B-3)'**
  String get table_number_invalid;

  /// Champ téléphone
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phone_number;

  /// Erreur champ téléphone vide
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone obligatoire'**
  String get phone_number_required;

  /// Erreur format téléphone
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide (format +226 00 00 00 00)'**
  String get phone_number_invalid;

  /// Bouton valider commande
  ///
  /// In fr, this message translates to:
  /// **'Commander'**
  String get place_order;

  /// Titre confirmation commande
  ///
  /// In fr, this message translates to:
  /// **'Commande confirmée'**
  String get order_confirmed;

  /// Statut en préparation
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get order_preparing;

  /// Statut commande prête
  ///
  /// In fr, this message translates to:
  /// **'Commande prête !'**
  String get order_ready;

  /// Statut commande livrée
  ///
  /// In fr, this message translates to:
  /// **'Commande livrée'**
  String get order_delivered;

  /// Statut commande annulée
  ///
  /// In fr, this message translates to:
  /// **'Commande annulée'**
  String get order_cancelled;

  /// Statut en attente
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get order_pending;

  /// Statut commande terminée
  ///
  /// In fr, this message translates to:
  /// **'Commande terminée'**
  String get order_completed;

  /// Libellé total
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// Montant formaté FCFA
  ///
  /// In fr, this message translates to:
  /// **'{amount} FCFA'**
  String total_amount(String amount);

  /// Titre section catégories
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// Filtre toutes catégories
  ///
  /// In fr, this message translates to:
  /// **'Tous les plats'**
  String get all_dishes;

  /// Onglet favoris
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// Badge plat du jour
  ///
  /// In fr, this message translates to:
  /// **'Plat du jour'**
  String get dish_of_the_day;

  /// Bouton ajouter au panier
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier'**
  String get add_to_cart;

  /// Titre écran notifications
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Message aucune notification
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get no_notifications;

  /// Action notifications
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer comme lu'**
  String get mark_all_read;

  /// Statut restaurant fermé
  ///
  /// In fr, this message translates to:
  /// **'Restaurant fermé'**
  String get restaurant_closed;

  /// Statut restaurant ouvert
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get restaurant_open;

  /// Bouton ouvrir dialog notation
  ///
  /// In fr, this message translates to:
  /// **'Noter la commande'**
  String get rate_order;

  /// Titre dialog notation
  ///
  /// In fr, this message translates to:
  /// **'Votre avis'**
  String get rating_title;

  /// Sous-titre dialog notation
  ///
  /// In fr, this message translates to:
  /// **'Comment s\'est passée votre commande ?'**
  String get rating_subtitle;

  /// Hint champ commentaire
  ///
  /// In fr, this message translates to:
  /// **'Commentaire (optionnel)...'**
  String get rating_comment_hint;

  /// Bouton soumettre
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get submit;

  /// Bouton annuler
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Bouton connexion
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// Bouton déconnexion
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// Bouton inscription
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get sign_up;

  /// Bouton mode invité
  ///
  /// In fr, this message translates to:
  /// **'Continuer en invité'**
  String get guest_mode;

  /// Champ email
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// Champ mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// Message aucune commande
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande'**
  String get no_orders;

  /// Sous-titre aucune commande
  ///
  /// In fr, this message translates to:
  /// **'Vos commandes apparaîtront ici'**
  String get no_orders_subtitle;

  /// Temps de préparation
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String preparation_time(int minutes);

  /// Nombre d'articles dans le panier
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun article} =1{1 article} other{{count} articles}}'**
  String items_count(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
