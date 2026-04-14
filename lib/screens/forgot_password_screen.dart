import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// Écran de réinitialisation du mot de passe (2 étapes) :
///   1. Saisie du téléphone → obtention du token (MVP : affiché en clair)
///   2. Saisie du token + nouveau mot de passe → confirmation
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Étape 1 : demande du code
  final _step1Key = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  // Étape 2 : réinitialisation
  final _step2Key = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  int _step = 1; // 1 = demande code | 2 = saisie token | 3 = succès

  // ─── Step 1 : envoyer téléphone ─────────────────────────────────────────

  Future<void> _requestToken() async {
    if (!_step1Key.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result =
        await AuthService.forgotPassword(_phoneController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // En MVP le token est retourné directement dans la réponse
      final token = result['reset_token'] as String?;
      if (token != null) _tokenController.text = token;

      setState(() => _step = 2);
    } else {
      _showError(result['message'] ?? 'Erreur');
    }
  }

  // ─── Step 2 : réinitialiser le mot de passe ─────────────────────────────

  Future<void> _resetPassword() async {
    if (!_step2Key.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await AuthService.resetPassword(
      token: _tokenController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _step = 3);
    } else {
      _showError(result['message'] ?? 'Token invalide ou expiré');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Validators ──────────────────────────────────────────────────────────

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Entrez votre numéro';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\.]'), '');
    final regex = RegExp(r'^(?:\+?226|00226)?[0-9]{8}$');
    if (!regex.hasMatch(cleaned)) return 'Numéro invalide (ex: 70 12 34 56)';
    return null;
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _phoneController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mot de passe oublié',
          style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _step == 1
                ? _buildStep1()
                : _step == 2
                    ? _buildStep2()
                    : _buildSuccess(),
          ),
        ),
      ),
    );
  }

  // ─── Étape 1 ─────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Card(
      key: const ValueKey(1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _step1Key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_reset, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Réinitialiser le mot de passe',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez votre numéro de téléphone pour recevoir un code de réinitialisation.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: _validatePhone,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _requestToken,
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text(
                          'Obtenir le code',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Étape 2 ─────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Card(
      key: const ValueKey(2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _step2Key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user,
                  size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Nouveau mot de passe', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Text(
                'Collez le code reçu et choisissez un nouveau mot de passe.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Champ code
              TextFormField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Code de réinitialisation',
                  prefixIcon:
                      const Icon(Icons.vpn_key, color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Le code est requis'
                    : null,
              ),
              const SizedBox(height: 16),

              // Nouveau mot de passe
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
              ),
              const SizedBox(height: 16),

              // Confirmation
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Confirmez le mot de passe';
                  }
                  if (v != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _isLoading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _resetPassword,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Réinitialiser',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _step = 1),
                child: const Text(
                  'Demander un nouveau code',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Succès ──────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Card(
      key: const ValueKey(3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 72, color: AppColors.success),
            const SizedBox(height: 20),
            const Text(
              'Mot de passe réinitialisé !',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Votre mot de passe a été modifié avec succès. Vous pouvez maintenant vous connecter.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text(
                  'Se connecter',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
