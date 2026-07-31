import 'package:flutter/material.dart';

import 'package:pixel_pocket/core/theme/app_color.dart';

extension PixelSnackBarMessenger on ScaffoldMessengerState {
  void showPixelSnackBar(String message, {bool isError = false}) {
    hideCurrentSnackBar();
    showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.expense : null,
      ),
    );
  }
}
