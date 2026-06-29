import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/pin_controller.dart';
import 'package:pixel_pocket/features/auth/presentation/widgets/pin_scaffold.dart';

class UnlockPinScreen extends ConsumerStatefulWidget {
  const UnlockPinScreen({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  ConsumerState<UnlockPinScreen> createState() => _UnlockPinScreenState();
}

class _UnlockPinScreenState extends ConsumerState<UnlockPinScreen> {
  static const _pinLength = 4;

  static const _maxAttempts = 6;

  static const _lockoutSeconds = 30;

  String _input = '';
  bool _error = false;
  bool _checking = false;
  int _wrongAttempts = 0;
  int _lockSecondsLeft = 0;
  Timer? _lockTimer;

  bool get _locked => _lockSecondsLeft > 0;

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  void _startLockout() {
    _lockSecondsLeft = _lockoutSeconds;
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _lockSecondsLeft--;
        if (_lockSecondsLeft <= 0) {
          timer.cancel();
          _wrongAttempts = 0;
        }
      });
    });
  }

  void _onDigit(String digit) {
    if (_locked || _checking || _input.length >= _pinLength) return;
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
      _wrongAttempts++;
      if (_wrongAttempts >= _maxAttempts) _startLockout();
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxAttempts - _wrongAttempts;
    final subtitle = _locked
        ? 'Too many attempts. Try again in ${_lockSecondsLeft}s'
        : _wrongAttempts == 0
        ? 'Unlock Pixel Pocket'
        : 'Wrong PIN — $remaining attempts left';
    return PinScaffold(
      title: 'Enter PIN',
      subtitle: subtitle,
      length: _pinLength,
      filled: _input.length,
      error: _error,
      keypadEnabled: !_locked,
      subtitleError: _wrongAttempts > 0,
      onDigit: _onDigit,
      onBackspace: _onBackspace,
    );
  }
}
