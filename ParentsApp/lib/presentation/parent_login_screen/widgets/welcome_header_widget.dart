import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WelcomeHeaderWidget extends StatelessWidget {
  const WelcomeHeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 6.w,
        right: 6.w,
        top: 6.h,
        bottom: 3.h,
      ),
      // Flat colour — no LinearGradient repainting on every keystroke
      color: AppTheme.primaryLight,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: 16.w,
              height: 16.w,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/AB_logo.jpg',
                  width: 16.w,
                  height: 16.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.directions_bus_rounded,
                    size: 8.w,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'ApoBasi',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            SizedBox(height: 0.3.h),
            Text(
              'Safe journeys, Happy parents',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
