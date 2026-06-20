import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/localization_provider.dart';
import '../providers/auth_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  String _enteredPin = '';
  String? _errorMessage;
  bool _biometricAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay to ensure providers are fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometric();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reset biometric flag on resume so the icon is clickable
    if (state == AppLifecycleState.resumed) {
      setState(() => _biometricAttempted = false);
    }
  }

  Future<void> _tryBiometric() async {
    if (_biometricAttempted) return; // Prevent double-trigger

    final auth = context.read<AuthProvider>();
    if (!auth.biometricAvailable || !auth.biometricEnabled) return;

    _biometricAttempted = true;
    final local = context.read<LocalizationProvider>();
    final success = await auth.authenticateWithBiometric(
      localizedReason: local.t('lock_biometric_reason'),
    );
    
    if (success && mounted) {
      auth.unlockApp();
    } else if (mounted) {
      // Allow manual retry via fingerprint icon
      setState(() => _biometricAttempted = false);
    }
  }

  void _onPinDigit(String digit) {
    if (_enteredPin.length >= 6) return;
    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 6) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    final auth = context.read<AuthProvider>();
    final isValid = await auth.verifyPinCode(_enteredPin);

    if (!mounted) return;

    if (isValid) {
      auth.unlockApp();
    } else {
      setState(() {
        _errorMessage = 'Неверный PIN-код';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final local = context.watch<LocalizationProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.surface,
              colors.surfaceContainerHighest.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Lock icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                local.t('lock_title'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                local.t('lock_subtitle'),
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                ),
              ),

              const Spacer(flex: 1),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? colors.primary
                          : colors.outline.withValues(alpha: 0.3),
                      border: !isFilled
                          ? Border.all(
                              color: colors.outline.withValues(alpha: 0.5),
                            )
                          : null,
                    ),
                  );
                }),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const Spacer(flex: 1),

              // Biometric button
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  if (!auth.biometricAvailable || !auth.biometricEnabled) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        Text(
                          local.t('lock_or'),
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        IconButton(
                          onPressed: _tryBiometric,
                          icon: Icon(
                            Icons.fingerprint,
                            size: 48,
                            color: colors.primary,
                          ),
                          tooltip: local.t('lock_biometric'),
                        ),
                        Text(
                          local.t('lock_biometric'),
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(flex: 2),

              // Numpad
              _buildNumpad(colors, local),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad(ColorScheme colors, LocalizationProvider local) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NumpadButton(digit: '1', onTap: () => _onPinDigit('1')),
              _NumpadButton(digit: '2', onTap: () => _onPinDigit('2')),
              _NumpadButton(digit: '3', onTap: () => _onPinDigit('3')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NumpadButton(digit: '4', onTap: () => _onPinDigit('4')),
              _NumpadButton(digit: '5', onTap: () => _onPinDigit('5')),
              _NumpadButton(digit: '6', onTap: () => _onPinDigit('6')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NumpadButton(digit: '7', onTap: () => _onPinDigit('7')),
              _NumpadButton(digit: '8', onTap: () => _onPinDigit('8')),
              _NumpadButton(digit: '9', onTap: () => _onPinDigit('9')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 80), // Empty space
              _NumpadButton(digit: '0', onTap: () => _onPinDigit('0')),
              SizedBox(
                width: 80,
                child: IconButton(
                  onPressed: _onDelete,
                  icon: Icon(
                    Icons.backspace_outlined,
                    color: colors.onSurface,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;

  const _NumpadButton({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 80,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: colors.primary.withValues(alpha: 0.1),
          highlightColor: colors.primary.withValues(alpha: 0.05),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
