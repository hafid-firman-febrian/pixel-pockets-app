import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkStatusNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setOnline() {
    if (!state) state = true;
  }

  void setOffline() {
    if (state) state = false;
  }
}

final networkStatusProvider = NotifierProvider<NetworkStatusNotifier, bool>(
  NetworkStatusNotifier.new,
);
