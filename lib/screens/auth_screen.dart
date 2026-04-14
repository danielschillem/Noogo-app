import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ===== VALIDATORS =====

  /// Numéro Burkina Faso : 8 chiffres optionnellement précédés de +226 ou 00226
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Entrez votre numéro de téléphone';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\.]'), '');
    final regex = RegExp(r'^(?:\+?226|00226)?[0-9]{8}$');
    if (!regex.hasMatch(cleaned)) return 'Numéro invalide (ex: 70 12 34 56)';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null; // facultatif
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Adresse email invalide';
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    final color = isError ? Colors.red : Colors.green;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (_isLogin) {
        result = await AuthService.login(
          _phoneController.text.trim(),
          _passwordController.text,
        );
      } else {
        result = await AuthService.register(
          _nameController.text.trim(),
          _phoneController.text.trim(),
          _passwordController.text,
          email: _emailController.text.isNotEmpty
              ? _emailController.text.trim()
              : null,
          confirmPassword: _confirmPasswordController.text,
        );
      }

      if (result['success'] == true) {
        // AuthService.login/register sauvegarde déjà le token et l'utilisateur
        _showMessage(
          _isLogin ? 'Connexion réussie ' : 'Inscription réussie ',
          isError: false,
        );

        if (!mounted) return;

        // Redirection vers la page d'accueil
        if (_isLogin) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          setState(() {
            _isLogin = true;
            // clear sensitive fields
            _passwordController.clear();
            _confirmPasswordController.clear();
            // keep phone/email so user can quickly login
          });
        }
      } else {
        _showMessage(result['message'] ?? 'Erreur');
      }
    } catch (e) {
      _showMessage('Erreur : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isConfirm = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword
          ? (isConfirm ? _obscureConfirmPassword : _obscurePassword)
          : false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (isConfirm ? _obscureConfirmPassword : _obscurePassword)
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.primary,
                ),
                onPressed: () => setState(() {
                  if (isConfirm) {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  } else {
                    _obscurePassword = !_obscurePassword;
                  }
                }),
              )
            : null,
      ),
      validator: validator,
    );
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
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top icon indicating mode (login / signup) with a small animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: Tween<double>(begin: 0.85, end: 1.0)
                              .animate(animation),
                          child:
                              FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: CircleAvatar(
                        key: ValueKey<bool>(_isLogin),
                        radius: 36,
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          _isLogin ? Icons.login : Icons.person_add,
                          size: 36,
                          color: Colors.white,
                          semanticLabel: _isLogin
                              ? 'Icône connexion'
                              : 'Icône inscription',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isLogin ? 'Connexion' : 'Inscription',
                      style: AppTextStyles.heading1,
                    ),
                    const SizedBox(height: 12),
                    if (!_isLogin)
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nom complet',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Entrez votre nom';
                          }
                          if (value.trim().length < 2) {
                            return 'Nom trop court (min. 2 caractères)';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      icon: Icons.phone,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),
                    if (!_isLogin)
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email (facultatif)',
                        icon: Icons.email,
                        validator: _validateEmail,
                      ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      icon: Icons.lock,
                      isPassword: true,
                      validator: (value) =>
                          value!.length < 6 ? 'Minimum 6 caractères' : null,
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirmer le mot de passe',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isConfirm: true,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Veuillez confirmer le mot de passe';
                          }
                          if (value != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isLogin
                                      ? Icons.login
                                      : Icons.app_registration,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isLogin ? 'Se connecter' : 'S\'inscrire',
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isLogin ? Icons.person_add : Icons.login,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isLogin
                                ? 'Pas de compte ? Inscrivez-vous'
                                : 'Déjà un compte ? Connectez-vous',
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    if (_isLogin) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
