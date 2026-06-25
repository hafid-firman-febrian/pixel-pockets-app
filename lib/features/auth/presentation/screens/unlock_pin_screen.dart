import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/pin_controller.dart';
import 'package:pixel_pocket/features/auth/presentation/widgets/pin_scaffold.dart';

/// Enter the PIN to unlock the app. On a correct PIN [onSuccess] fires; on a
/// wrong one the dots shake and the input resets. UI only — verification lives
/// in the service.
class UnlockPinScreen extends ConsumerStatefulWidget {
  const UnlockPinScreen({super.key, this.onSuccess});

  /// Called once the entered PIN is verified correct.
  final VoidCallback? onSuccess;

  @override
  ConsumerState<UnlockPinScreen> createState() => _UnlockPinScreenState();
}

class _UnlockPinScreenState extends ConsumerState<UnlockPinScreen> {
  static const _pinLength = 4;

  String _input = '';
  bool _error = false;
  bool _checking = false;

  void _onDigit(String digit) {
    if (_checking || _input.length >= _pinLength) return;
    setState(() {
      _error = false;
      _input += digit;
    });
    if (_input.length == _pinLength) _verify();
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() {
      _error = false;
      _input = _input.substring(0, _input.length - 1);
    });
  }

  Future<void> _verify() async {
    setState(() => _checking = true);
    final ok = await ref.read(pinControllerProvider.notifier).verifyPin(_input);
    if (!mounted) return;

    if (ok) {
      widget.onSuccess?.call();
      return;
    }
    setState(() {
      _error = true;
      _input = '';
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PinScaffold(
      title: 'Masukkan PIN',
      subtitle: 'Buka kunci Pixel Pocket',
      length: _pinLength,
      filled: _input.length,
      error: _error,
      onDigit: _onDigit,
      onBackspace: _onBackspace,
    );
  }
}
