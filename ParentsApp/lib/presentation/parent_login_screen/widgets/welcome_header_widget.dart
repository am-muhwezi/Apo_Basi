import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/app_export.dart';

class WelcomeHeaderWidget extends StatelessWidget {
  const WelcomeHeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8.w),
          bottomRight: Radius.circular(8.w),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 2.h),
            SvgPicture.asset(
              'assets/images/splash_logo.svg',
              width: 45.w,
              height: 45.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Welcome Back',
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Sign in to track your child\'s bus journey safely',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
