import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  Color backgroundColor = const Color(0xFF1A3C34),
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: backgroundColor,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    duration: duration,
  ));
}
