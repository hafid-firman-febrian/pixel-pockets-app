import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/pin_controller.dart';
import 'package:pixel_pocket/features/auth/presentation/widgets/pin_scaffold.dart';
import 'package:pixelarticons/pixel.dart';

class SetPinScreen extends ConsumerStatefulWidget {
  const SetPinScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  static const _pinLength = 4;

  String? _firstEntry;
  String _input = '';
  bool _error = false;
  bool _saving = false;

  bool get _confirming => _firstEntry != null;

  void _onDigit(String digit) {
    if (_saving || _input.length >= _pinLength) return;
    setState(() {
      _error = false;
      _input += digit;
    });
    if (_input.length == _pinLength) _onFilled();
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() {
      _error = false;
      _input = _input.substring(0, _input.length - 1);
    });
  }

  Future<void> _onFilled() async {
    if (!_confirming) {
      setState(() {
        _firstEntry = _input;
        _input = '';
      });
      return;
    }

    if (_input != _firstEntry) {
      setState(() {
        _error = true;
        _firstEntry = null;
        _input = '';
      });
      return;
    }

    setState(() => _saving = true);
    await ref.read(pinControllerProvider.notifier).setPin(_input);
    if (!mounted) return;
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return PinScaffold(
      icon: Pixel.lockopen,
      title: _confirming ? 'Confirm PIN' : 'Create PIN',
      subtitle: _confirming
          ? 'Re-enter your PIN'
          : 'Create a 4-digit PIN for quick lock',
      length: _pinLength,
      filled: _input.length,
      error: _error,
      onDigit: _onDigit,
      onBackspace: _onBackspace,
    );
  }
}
