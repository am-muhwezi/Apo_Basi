import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WelcomeHeaderWidget extends StatelessWidget {
  const WelcomeHeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1), // Modern indigo
            Color(0xFF8B5CF6), // Purple
            Color(0xFFEC4899), // Pink accent
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 4.h),
            // Modern icon instead of image
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_bus_rounded,
                size: 12.w,
                color: Color(0xFF6366F1),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'ApoBasi',
              style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 32.sp,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Track Your Child\'s Journey',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}
