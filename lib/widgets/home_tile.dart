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
    fontFamily: "RobotoMono",
    color: Color(0xFF37393F),
  );

  static const _iconColor = Color(0xFF37393F);

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
      child: child ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon!, color: _iconColor, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label!,
                  style: _labelStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
    );
  }
}
