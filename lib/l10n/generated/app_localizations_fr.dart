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

  @override
  String get delivery_address => 'Adresse de livraison';

  @override
  String get delivery_address_hint =>
      'Ex: Quartier Zogona, Rue 15.32, Porte 45';

  @override
  String get delivery_address_required =>
      'Veuillez entrer une adresse valide (min. 5 car.)';

  @override
  String get delivery_subtitle => 'Se faire livrer à domicile';

  @override
  String get change_password => 'Changer le mot de passe';

  @override
  String get current_password => 'Mot de passe actuel';

  @override
  String get new_password => 'Nouveau mot de passe';

  @override
  String get confirm_password => 'Confirmer le mot de passe';

  @override
  String get password_changed => 'Mot de passe modifié avec succès';

  @override
  String get password_min_length => 'Minimum 6 caractères';

  @override
  String get password_mismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get my_restaurants => 'Mes restaurants enregistrés';

  @override
  String get personal_info => 'Mes informations personnelles';

  @override
  String get delivery_addresses => 'Adresses de livraison';

  @override
  String get payment_methods => 'Méthodes de paiement';

  @override
  String get order_history => 'Historique des commandes';

  @override
  String get notification_settings => 'Notifications';

  @override
  String get help_support => 'Aide et support';

  @override
  String get about => 'À propos';

  @override
  String get dark_mode => 'Mode sombre';

  @override
  String get edit_profile => 'Modifier le profil';

  @override
  String get confirm_order => 'Confirmer la commande';

  @override
  String get empty_cart => 'Votre panier est vide';

  @override
  String get clear_cart => 'Vider le panier';

  @override
  String get order_success => 'Commande envoyée avec succès !';

  @override
  String get order_error => 'Erreur lors de l\'envoi de la commande';

  @override
  String get track_order => 'Suivre la commande';

  @override
  String get reorder => 'Recommander';

  @override
  String get rated => 'Noté';

  @override
  String get rate => 'Évaluer';

  @override
  String get thank_you_rating => 'Merci pour votre évaluation !';

  @override
  String order_number(int id) {
    return 'Commande #$id';
  }

  @override
  String order_count(int count) {
    return '$count commande(s)';
  }

  @override
  String get my_orders => 'Mes Commandes';

  @override
  String get close => 'Fermer';

  @override
  String get modify => 'Modifier';

  @override
  String get confirm => 'Confirmer';

  @override
  String get return_back => 'Retour';

  @override
  String get validate => 'Valider';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get search => 'Rechercher';

  @override
  String get search_dishes => 'Rechercher un plat…';

  @override
  String get popular_dishes => 'Plats populaires';

  @override
  String get see_all => 'Voir tout';

  @override
  String get quick_order => 'Commande rapide';

  @override
  String get offline_mode => 'Mode hors-ligne';

  @override
  String get offline_subtitle =>
      'Connexion limitée — données locales affichées';

  @override
  String get connection_error => 'Erreur de connexion';

  @override
  String get scan_qr_manual => 'Entrer le code manuellement';

  @override
  String get welcome_title => 'Bienvenue sur Noogo';

  @override
  String get create_account => 'Créez votre compte NOOGO';

  @override
  String get connect_benefits =>
      'Connectez-vous pour accéder à votre profil, suivre vos commandes et bénéficier d\'avantages exclusifs.';

  @override
  String get sign_in_up => 'Se connecter / S\'inscrire';

  @override
  String get continue_without_account => 'Continuer sans compte';

  @override
  String get logout_confirm => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get logout_success => 'Déconnexion réussie';

  @override
  String get login_success => 'Connexion réussie !';

  @override
  String get profile_updated => 'Profil mis à jour avec succès';

  @override
  String get guest_mode_enabled => 'Mode invité activé';

  @override
  String get added_to_cart => 'Ajouté au panier';

  @override
  String get items_added_to_cart => 'Plats ajoutés au panier';

  @override
  String get order_cancelled_success => 'Commande annulée avec succès !';

  @override
  String get cancel_order => 'Annuler la commande';

  @override
  String cancel_order_confirm(int id) {
    return 'Voulez-vous vraiment annuler la commande #$id ?';
  }

  @override
  String get discover_menu => 'Découvrir le menu';

  @override
  String get change_restaurant => 'Changer de restaurant';

  @override
  String get full_name => 'Nom complet';

  @override
  String get phone => 'Téléphone';

  @override
  String get member_since => 'Membre depuis';

  @override
  String get my_stats => 'Mes statistiques';

  @override
  String get points => 'Points';

  @override
  String get no_address_saved => 'Aucune adresse enregistrée';

  @override
  String get new_address => 'Nouvelle adresse...';

  @override
  String get order_updates => 'Mises à jour commandes';

  @override
  String get order_updates_subtitle => 'Statut de vos commandes en temps réel';

  @override
  String get promotions => 'Promotions';

  @override
  String get promotions_subtitle => 'Offres et réductions';

  @override
  String get delivery_alerts => 'Alertes livraison';

  @override
  String get delivery_alerts_subtitle => 'Position du livreur et arrivée';

  @override
  String get about_version => 'NOOGO v1.4.0';

  @override
  String get about_description => 'Application de commande de repas';

  @override
  String get about_copyright => '© 2026 Quick dev-it. Tous droits réservés.';

  @override
  String get forgot_password => 'Mot de passe oublié ?';

  @override
  String get reset_password => 'Réinitialiser le mot de passe';

  @override
  String get name_required => 'Veuillez entrer votre nom';

  @override
  String get enter_name => 'Entrez votre nom';

  @override
  String get enter_phone => 'Numéro de téléphone';

  @override
  String get enter_email => 'Email (optionnel)';

  @override
  String get enter_password => 'Mot de passe';

  @override
  String get order_summary => 'Récapitulatif';

  @override
  String get delivery_fee => 'Frais de livraison';

  @override
  String get subtotal => 'Sous-total';
}
