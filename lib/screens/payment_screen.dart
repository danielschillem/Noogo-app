import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/payment_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// Écran de paiement Mobile Money Noogo.
///
/// Reçoit les paramètres du panier, orchestre le flow complet :
///   1. Initiation (appel backend)
///   2. Instruction USSD → OTP
///   3. Saisie OTP + validation backend
///   4. Polling statut (mode gateway réelle)
///   5. Résultat (succès / échec / expiration)
///
/// Retourne [PaymentRecord] si le paiement est complété, ou null si annulé.

class PaymentScreen extends StatefulWidget {
  final int restaurantId;
  final String provider; // 'orange' | 'moov' | 'wave' | 'telecel'
  final String phone;
  final int amount;
  final int? orderId;

  const PaymentScreen({
    super.key,
    required this.restaurantId,
    required this.provider,
    required this.phone,
    required this.amount,
    this.orderId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum _Step { initiating, waitingOtp, verifyingOtp, polling, done, error }

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  _Step _step = _Step.initiating;
  String _statusMessage = 'Connexion au service de paiement…';
  String? _errorMessage;
  PaymentRecord? _payment;
  bool _isSimulation = false;

  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();

  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initiate();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  // ─── Flow ──────────────────────────────────────────────────────────────────

  Future<void> _initiate() async {
    setState(() {
      _step = _Step.initiating;
      _statusMessage =
          'Envoi de la demande à ${PaymentService.providerLabel(widget.provider)}…';
    });

    final result = await PaymentService.initiate(
      restaurantId: widget.restaurantId,
      provider: widget.provider,
      phone: widget.phone,
      amount: widget.amount,
      orderId: widget.orderId,
    );

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _step = _Step.error;
        _errorMessage = result.message;
      });
      return;
    }

    _payment = result.payment;
    _isSimulation = result.mode == 'simulation';

    setState(() {
      _step = _Step.waitingOtp;
      _statusMessage = _isSimulation
          ? 'Mode démo : utilisez le code OTP → 1234'
          : 'Vérifiez votre téléphone — validez la demande USSD puis entrez l\'OTP reçu';
    });

    // En mode simulation, pré-remplir l'OTP pour la démo
    if (_isSimulation) {
      _otpController.text = '';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocus.requestFocus();
    });
  }

  Future<void> _submitOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    if (_payment == null) {
      setState(() {
        _step = _Step.error;
        _errorMessage = 'Erreur interne : paiement non initialisé';
      });
      return;
    }

    setState(() {
      _step = _Step.verifyingOtp;
      _statusMessage = 'Vérification du code OTP…';
    });

    final result = await PaymentService.confirmOtp(
      paymentId: _payment!.id,
      otp: otp,
    );

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _step = _Step.waitingOtp;
        _errorMessage = result.message;
        _otpController.clear();
      });
      _otpFocus.requestFocus();
      return;
    }

    _payment = result.payment ?? _payment;
    _errorMessage = null;

    if (_payment!.status.isCompleted) {
      setState(() => _step = _Step.done);
      _finishWithSuccess();
      return;
    }

    // Gateway réelle → polling
    setState(() {
      _step = _Step.polling;
      _statusMessage = 'Confirmation en cours…';
    });

    final final_ = await PaymentService.pollUntilDone(
      paymentId: _payment!.id,
      onStatus: (s) {
        if (mounted) {
          setState(() {
            _statusMessage = switch (s) {
              PaymentStatus.processing => 'Traitement en cours…',
              PaymentStatus.completed => 'Paiement confirmé !',
              PaymentStatus.failed => 'Paiement refusé',
              PaymentStatus.expired => 'Délai dépassé',
              _ => 'En attente…',
            };
          });
        }
      },
    );

    if (!mounted) return;

    _payment = final_ ?? _payment;

    if (_payment!.status.isCompleted) {
      setState(() => _step = _Step.done);
      _finishWithSuccess();
    } else {
      setState(() {
        _step = _Step.error;
        _errorMessage = switch (_payment!.status) {
          PaymentStatus.expired => 'Le délai de paiement a expiré',
          PaymentStatus.failed => 'Le paiement a été refusé par l\'opérateur',
          PaymentStatus.cancelled => 'Paiement annulé',
          _ => 'Paiement non abouti',
        };
      });
    }
  }

  void _finishWithSuccess() {
    if (!mounted) return;
    Navigator.of(context).pop(_payment);
  }

  void _cancel() {
    if (_payment != null && _payment!.status.isActive) {
      PaymentService.cancel(_payment!.id);
    }
    Navigator.of(context).pop(null);
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Annuler le paiement ?'),
              content: const Text(
                  'Le paiement sera annulé. Votre commande restera en attente.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continuer'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    _cancel();
                  },
                  child: const Text('Annuler le paiement'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Paiement Mobile Money'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            if (_step != _Step.done)
              TextButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Annuler ?'),
                    content:
                        const Text('Confirmer l\'annulation du paiement ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Non'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                          _cancel();
                        },
                        child: const Text('Oui, annuler'),
                      ),
                    ],
                  ),
                ),
                child: const Text('Annuler',
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                _buildProviderBadge(),
                const SizedBox(height: 24),
                _buildAmountDisplay(),
                const SizedBox(height: 32),
                _buildStepContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderBadge() {
    final color = Color(PaymentService.providerColorValue(widget.provider));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child:
                const Icon(Icons.phone_android, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                PaymentService.providerLabel(widget.provider),
                style: AppTextStyles.bodyLarge
                    .copyWith(fontWeight: FontWeight.w700, color: color),
              ),
              Text(widget.phone,
                  style: AppTextStyles.caption.copyWith(color: Colors.black54)),
            ],
          ),
          if (_isSimulation) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('DÉMO',
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Column(
      children: [
        Text('Montant à payer',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.black45)),
        const SizedBox(height: 4),
        Text(
          '${widget.amount.toStringAsFixed(0)} FCFA',
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.primary,
            fontSize: 36,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      _Step.initiating => _buildLoader(_statusMessage),
      _Step.waitingOtp => _buildOtpInput(),
      _Step.verifyingOtp => _buildLoader('Vérification du code OTP…'),
      _Step.polling => _buildLoader(_statusMessage),
      _Step.done => _buildSuccess(),
      _Step.error => _buildError(),
    };
  }

  Widget _buildLoader(String message) {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulse,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(message,
            style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text('Instructions',
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800)),
                ],
              ),
              const SizedBox(height: 8),
              if (_isSimulation)
                Text(
                  '🔧 Mode démo actif\nSaisissez le code OTP : 1234',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.blue.shade700),
                )
              else
                Text(
                  '1. Vérifiez votre téléphone\n'
                  '2. Acceptez la demande USSD\n'
                  '3. Entrez votre code PIN\n'
                  '4. Notez le code OTP reçu et saisissez-le ci-dessous',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.blue.shade700),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Champ OTP
        Text('Code OTP',
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _otpController,
          focusNode: _otpFocus,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 10,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle:
                const TextStyle(letterSpacing: 10, color: Colors.black26),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onSubmitted: (_) => _submitOtp(),
        ),

        // Message d'erreur OTP
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_errorMessage!,
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.error)),
              ),
            ],
          ),
        ],

        const SizedBox(height: 28),

        // Bouton valider
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitOtp,
            icon: const Icon(Icons.lock_open),
            label: const Text('Valider le paiement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: AppTextStyles.button,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Renvoyer
        Center(
          child: TextButton.icon(
            onPressed: _initiate,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Renvoyer la demande'),
            style: TextButton.styleFrom(foregroundColor: Colors.black45),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                color: AppColors.success, size: 72),
          ),
        ),
        const SizedBox(height: 20),
        Text('Paiement réussi !',
            style: AppTextStyles.heading2.copyWith(color: AppColors.success)),
        const SizedBox(height: 8),
        Text(
          'Votre paiement de ${widget.amount} FCFA\na bien été confirmé.',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.black45),
          textAlign: TextAlign.center,
        ),
        if (_payment?.operatorTransactionId != null) ...[
          const SizedBox(height: 8),
          Text(
            'Réf: ${_payment!.operatorTransactionId}',
            style: AppTextStyles.caption.copyWith(color: Colors.black38),
          ),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _finishWithSuccess,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continuer'),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.error_outline, color: AppColors.error, size: 72),
        ),
        const SizedBox(height: 20),
        Text('Paiement non abouti',
            style: AppTextStyles.heading2.copyWith(color: AppColors.error)),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Une erreur inattendue est survenue',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.black45),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black54,
                  side: const BorderSide(color: AppColors.dividerColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _initiate,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
