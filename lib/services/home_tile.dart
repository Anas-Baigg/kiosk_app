import 'package:flutter/material.dart';

class HomeTileButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? label;
  final Widget? child;

  const HomeTileButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  }) : child = null;

  const HomeTileButton.custom({
    super.key,
    required this.onPressed,
    required this.child,
  }) : icon = null,
       label = null;

  static const _labelStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.normal,
    fontFamily: "RobotoMono",
    color: Color.fromARGB(255, 55, 63, 81),
  );

  static const _iconColor = Color.fromARGB(255, 55, 63, 81);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        ),
      ),
      child:
          child ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon!, color: _iconColor, size: 22),
              const SizedBox(width: 10),
              Text(label!, style: _labelStyle),
            ],
          ),
    );
  }
}
