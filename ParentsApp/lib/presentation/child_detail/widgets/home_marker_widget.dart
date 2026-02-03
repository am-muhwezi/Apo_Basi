import 'package:flutter/material.dart';

class HomeMarkerWidget extends StatelessWidget {
  const HomeMarkerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF5B7FFF),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.home_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
