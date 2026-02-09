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
        top: 6.h,
        bottom: 3.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withOpacity(0.85),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App Logo - Compact
            Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/AB_logo.jpg',
                  width: 16.w,
                  height: 16.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.directions_bus_rounded,
                      size: 8.w,
                      color: AppTheme.primaryLight,
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: 2.h),

            // App Name - Sleek
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

            // Tagline - Compact
            Text(
              'Safe journeys, Happy parents',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
