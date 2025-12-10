import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Custom home marker widget for child detail map
/// Displays a blue pin with home icon
class HomeMarkerWidget extends StatelessWidget {
  const HomeMarkerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 2.w,
            vertical: 0.5.h,
          ),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🏠',
                style: TextStyle(fontSize: 12.sp),
              ),
              SizedBox(width: 1.w),
              Text(
                'Home',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),
        // Pin
        Icon(
          Icons.location_on,
          color: Colors.blue,
          size: 40,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ],
    );
  }
}
