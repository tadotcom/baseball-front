import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;

  const PrimaryButton({
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ButtonStyle? themeStyle = Theme.of(context).elevatedButtonTheme.style;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: themeStyle,
      child: isLoading
          ? SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          color: themeStyle?.foregroundColor?.resolve({}),
          strokeWidth: 3,
        ),
      )
          : Text(text),
    );
  }
}