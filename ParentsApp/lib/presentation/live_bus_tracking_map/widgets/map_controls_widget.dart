import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MapControlsWidget extends StatelessWidget {
  final VoidCallback onCenterOnBus;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleLayer;
  final bool isLayerToggled;

  const MapControlsWidget({
    Key? key,
    required this.onCenterOnBus,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleLayer,
    required this.isLayerToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 4.w,
      top: 15.h,
      child: Column(
        children: [
          _buildControlButton(
            iconName: 'my_location',
            onTap: onCenterOnBus,
            tooltip: 'Center on Bus',
          ),
          SizedBox(height: 1.h),
          _buildControlButton(
            iconName: 'add',
            onTap: onZoomIn,
            tooltip: 'Zoom In',
          ),
          SizedBox(height: 1.h),
          _buildControlButton(
            iconName: 'remove',
            onTap: onZoomOut,
            tooltip: 'Zoom Out',
          ),
          SizedBox(height: 1.h),
          _buildControlButton(
            iconName: isLayerToggled ? 'layers' : 'layers_outlined',
            onTap: onToggleLayer,
            tooltip: 'Toggle Layer',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String iconName,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Container(
      width: 12.w,
      height: 6.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Tooltip(
            message: tooltip,
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
