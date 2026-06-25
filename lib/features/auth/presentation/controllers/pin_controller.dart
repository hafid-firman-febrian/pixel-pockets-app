import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/auth/application/services/pin_service.dart';

/// Owns the local PIN status and exposes set/verify/clear.
///
/// State is `bool?`: `null` while the initial lookup is in flight, then `true`
/// (a PIN exists) or `false` (none yet). The router reads this synchronously to
/// decide whether to send a freshly signed-in user to the set-PIN screen.
final pinControllerProvider = NotifierProvider<PinController, bool?>(
  PinController.new,
);

class PinController extends Notifier<bool?> {
  PinService get _service => ref.read(pinServiceProvider);

  @override
  bool? build() {
    _load();
    return null; // unknown until the secure store is read
  }

  Future<void> _load() async {
    try {
      state = await _service.hasPin();
    } catch (_) {
      // A read failure must not leave the gate stuck on null forever.
      state = false;
    }
  }

  /// Creates (or replaces) the PIN, then marks a PIN as present.
  Future<void> setPin(String pin) async {
    await _service.setPin(pin);
    state = true;
  }

  /// Checks an entered PIN against the stored hash. Does not mutate state.
  Future<bool> verifyPin(String pin) => _service.verifyPin(pin);

  /// Removes the PIN (e.g. on logout).
  Future<void> clearPin() async {
    await _service.clearPin();
    state = false;
  }
}
