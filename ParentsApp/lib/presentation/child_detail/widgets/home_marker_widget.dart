import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Custom home marker widget for child detail map
/// Displays a blue pin with home icon
class HomeMarkerWidget extends StatelessWidget {
  const HomeMarkerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Pin icon (centered)
          Positioned(
            bottom: 0,
            child: Icon(
              Icons.location_on,
              color: Colors.blue,
              size: 36,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          // Label (above pin, can overflow the bounds)
          Positioned(
            top: -8,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '🏠',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
