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

  /// Champ adresse de livraison
  ///
  /// In fr, this message translates to:
  /// **'Adresse de livraison'**
  String get delivery_address;

  /// Hint adresse de livraison
  ///
  /// In fr, this message translates to:
  /// **'Ex: Quartier Zogona, Rue 15.32, Porte 45'**
  String get delivery_address_hint;

  /// Erreur adresse trop courte
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer une adresse valide (min. 5 car.)'**
  String get delivery_address_required;

  /// Sous-titre option livraison
  ///
  /// In fr, this message translates to:
  /// **'Se faire livrer à domicile'**
  String get delivery_subtitle;

  /// Menu changer mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get change_password;

  /// Champ mot de passe actuel
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get current_password;

  /// Champ nouveau mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get new_password;

  /// Champ confirmer mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirm_password;

  /// Message succès changement MDP
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié avec succès'**
  String get password_changed;

  /// Erreur MDP trop court
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get password_min_length;

  /// Erreur MDP pas identiques
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get password_mismatch;

  /// Menu mes restaurants
  ///
  /// In fr, this message translates to:
  /// **'Mes restaurants enregistrés'**
  String get my_restaurants;

  /// Menu infos perso
  ///
  /// In fr, this message translates to:
  /// **'Mes informations personnelles'**
  String get personal_info;

  /// Menu adresses livraison
  ///
  /// In fr, this message translates to:
  /// **'Adresses de livraison'**
  String get delivery_addresses;

  /// Menu méthodes paiement
  ///
  /// In fr, this message translates to:
  /// **'Méthodes de paiement'**
  String get payment_methods;

  /// Menu historique
  ///
  /// In fr, this message translates to:
  /// **'Historique des commandes'**
  String get order_history;

  /// Menu notifications settings
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notification_settings;

  /// Menu aide
  ///
  /// In fr, this message translates to:
  /// **'Aide et support'**
  String get help_support;

  /// Menu à propos
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// Toggle mode sombre
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get dark_mode;

  /// Bouton modifier profil
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get edit_profile;

  /// Titre confirmation commande
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la commande'**
  String get confirm_order;

  /// Message panier vide (alt)
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est vide'**
  String get empty_cart;

  /// Action vider le panier
  ///
  /// In fr, this message translates to:
  /// **'Vider le panier'**
  String get clear_cart;

  /// Message succès commande
  ///
  /// In fr, this message translates to:
  /// **'Commande envoyée avec succès !'**
  String get order_success;

  /// Message erreur commande
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'envoi de la commande'**
  String get order_error;

  /// Bouton suivre commande
  ///
  /// In fr, this message translates to:
  /// **'Suivre la commande'**
  String get track_order;

  /// Bouton recommander
  ///
  /// In fr, this message translates to:
  /// **'Recommander'**
  String get reorder;

  /// Label déjà noté
  ///
  /// In fr, this message translates to:
  /// **'Noté'**
  String get rated;

  /// Bouton évaluer
  ///
  /// In fr, this message translates to:
  /// **'Évaluer'**
  String get rate;

  /// Message merci après note
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre évaluation !'**
  String get thank_you_rating;

  /// Titre commande avec numéro
  ///
  /// In fr, this message translates to:
  /// **'Commande #{id}'**
  String order_number(int id);

  /// Compteur de commandes
  ///
  /// In fr, this message translates to:
  /// **'{count} commande(s)'**
  String order_count(int count);

  /// Titre section commandes
  ///
  /// In fr, this message translates to:
  /// **'Mes Commandes'**
  String get my_orders;

  /// Bouton fermer
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// Bouton modifier
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modify;

  /// Bouton confirmer
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// Bouton retour
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get return_back;

  /// Bouton valider
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// Bouton enregistrer
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// Bouton supprimer
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// Confirmation oui
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// Confirmation non
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// Champ recherche
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// Hint recherche plats
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un plat…'**
  String get search_dishes;

  /// Section plats populaires
  ///
  /// In fr, this message translates to:
  /// **'Plats populaires'**
  String get popular_dishes;

  /// Bouton voir tout
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get see_all;

  /// Section commande rapide
  ///
  /// In fr, this message translates to:
  /// **'Commande rapide'**
  String get quick_order;

  /// Bannière hors-ligne
  ///
  /// In fr, this message translates to:
  /// **'Mode hors-ligne'**
  String get offline_mode;

  /// Sous-titre hors-ligne
  ///
  /// In fr, this message translates to:
  /// **'Connexion limitée — données locales affichées'**
  String get offline_subtitle;

  /// Message erreur réseau
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion'**
  String get connection_error;

  /// Fallback saisie manuelle QR
  ///
  /// In fr, this message translates to:
  /// **'Entrer le code manuellement'**
  String get scan_qr_manual;

  /// Titre écran bienvenue
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Noogo'**
  String get welcome_title;

  /// Titre profil invité
  ///
  /// In fr, this message translates to:
  /// **'Créez votre compte NOOGO'**
  String get create_account;

  /// Description profil invité
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour accéder à votre profil, suivre vos commandes et bénéficier d\'avantages exclusifs.'**
  String get connect_benefits;

  /// Bouton connexion/inscription
  ///
  /// In fr, this message translates to:
  /// **'Se connecter / S\'inscrire'**
  String get sign_in_up;

  /// Lien invité
  ///
  /// In fr, this message translates to:
  /// **'Continuer sans compte'**
  String get continue_without_account;

  /// Message confirmation déconnexion
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter ?'**
  String get logout_confirm;

  /// Message succès déconnexion
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion réussie'**
  String get logout_success;

  /// Message succès connexion
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie !'**
  String get login_success;

  /// Message succès profil
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès'**
  String get profile_updated;

  /// Message mode invité
  ///
  /// In fr, this message translates to:
  /// **'Mode invité activé'**
  String get guest_mode_enabled;

  /// Snackbar ajout panier
  ///
  /// In fr, this message translates to:
  /// **'Ajouté au panier'**
  String get added_to_cart;

  /// Snackbar reorder
  ///
  /// In fr, this message translates to:
  /// **'Plats ajoutés au panier'**
  String get items_added_to_cart;

  /// Snackbar annulation
  ///
  /// In fr, this message translates to:
  /// **'Commande annulée avec succès !'**
  String get order_cancelled_success;

  /// Titre dialog annulation
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande'**
  String get cancel_order;

  /// Message confirmation annulation
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment annuler la commande #{id} ?'**
  String cancel_order_confirm(int id);

  /// Bouton vers menu
  ///
  /// In fr, this message translates to:
  /// **'Découvrir le menu'**
  String get discover_menu;

  /// Menu changer restaurant
  ///
  /// In fr, this message translates to:
  /// **'Changer de restaurant'**
  String get change_restaurant;

  /// Champ nom complet
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get full_name;

  /// Champ téléphone
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// Label date inscription
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis'**
  String get member_since;

  /// Section statistiques profil
  ///
  /// In fr, this message translates to:
  /// **'Mes statistiques'**
  String get my_stats;

  /// Label points fidélité
  ///
  /// In fr, this message translates to:
  /// **'Points'**
  String get points;

  /// Message aucune adresse
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse enregistrée'**
  String get no_address_saved;

  /// Hint nouvelle adresse
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle adresse...'**
  String get new_address;

  /// Toggle notifs commandes
  ///
  /// In fr, this message translates to:
  /// **'Mises à jour commandes'**
  String get order_updates;

  /// Description notifs commandes
  ///
  /// In fr, this message translates to:
  /// **'Statut de vos commandes en temps réel'**
  String get order_updates_subtitle;

  /// Toggle notifs promos
  ///
  /// In fr, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// Description notifs promos
  ///
  /// In fr, this message translates to:
  /// **'Offres et réductions'**
  String get promotions_subtitle;

  /// Toggle notifs livraison
  ///
  /// In fr, this message translates to:
  /// **'Alertes livraison'**
  String get delivery_alerts;

  /// Description notifs livraison
  ///
  /// In fr, this message translates to:
  /// **'Position du livreur et arrivée'**
  String get delivery_alerts_subtitle;

  /// Version affichée dans à propos
  ///
  /// In fr, this message translates to:
  /// **'NOOGO v1.4.0'**
  String get about_version;

  /// Description à propos
  ///
  /// In fr, this message translates to:
  /// **'Application de commande de repas'**
  String get about_description;

  /// Copyright à propos
  ///
  /// In fr, this message translates to:
  /// **'© 2026 Quick dev-it. Tous droits réservés.'**
  String get about_copyright;

  /// Lien mot de passe oublié
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgot_password;

  /// Titre réinitialisation MDP
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get reset_password;

  /// Erreur nom vide
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre nom'**
  String get name_required;

  /// Hint nom
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre nom'**
  String get enter_name;

  /// Hint téléphone auth
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get enter_phone;

  /// Hint email
  ///
  /// In fr, this message translates to:
  /// **'Email (optionnel)'**
  String get enter_email;

  /// Hint MDP
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get enter_password;

  /// Titre récapitulatif commande
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get order_summary;

  /// Label frais livraison
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison'**
  String get delivery_fee;

  /// Label sous-total
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get subtotal;
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
