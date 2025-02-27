import 'package:flutter/material.dart';

class CardLoading extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsets margin;

  const CardLoading({
    super.key,
    required this.width,
    required this.height,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}