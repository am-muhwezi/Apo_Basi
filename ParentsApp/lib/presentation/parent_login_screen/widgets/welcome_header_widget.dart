import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Apple-inspired welcome header with ApoBasi branding
/// Uses subtle gradient in brand blue with clean, minimal design
class WelcomeHeaderWidget extends StatelessWidget {
  const WelcomeHeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 6.w,
        right: 6.w,
        top: 8.h,
        bottom: 4.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight, // ApoBasi blue
            AppTheme.primaryLight.withOpacity(0.85), // Subtle variation
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App Icon - Clean, minimal
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_bus_rounded,
                size: 10.w,
                color: AppTheme.primaryLight,
              ),
            ),

            SizedBox(height: 3.h),

            // App Name - Bold, confident
            Text(
              'ApoBasi',
              style: GoogleFonts.inter(
                fontSize: 34, // iOS Large Title size
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),

            SizedBox(height: 0.5.h),

            // Tagline - Subtle, reassuring
            Text(
              'Safe journeys, Happy parents',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 17, // iOS body size
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
