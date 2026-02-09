import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AccountSettingsWidget extends StatefulWidget {
  final Map<String, dynamic> accountData;
  final Function(Map<String, dynamic>) onAccountUpdated;

  const AccountSettingsWidget({
    Key? key,
    required this.accountData,
    required this.onAccountUpdated,
  }) : super(key: key);

  @override
  State<AccountSettingsWidget> createState() => _AccountSettingsWidgetState();
}

class _AccountSettingsWidgetState extends State<AccountSettingsWidget> {
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _biometricEnabled = false;
  bool _showPasswordFields = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _biometricEnabled =
        widget.accountData['biometricEnabled'] as bool? ?? false;
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordChange() {
    setState(() {
      _showPasswordFields = !_showPasswordFields;
      if (!_showPasswordFields) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  void _changePassword() {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all password fields');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('New passwords do not match');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters long');
      return;
    }

    // Mock password validation
    if (_currentPasswordController.text != 'parent123') {
      _showErrorSnackBar('Current password is incorrect');
      return;
    }

    // Update account data
    final updatedData = Map<String, dynamic>.from(widget.accountData);
    updatedData['password'] = _newPasswordController.text;
    widget.onAccountUpdated(updatedData);

    // Clear fields and hide
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _showPasswordFields = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password changed successfully'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _toggleBiometric(bool value) {
    setState(() {
      _biometricEnabled = value;
    });

    final updatedData = Map<String, dynamic>.from(widget.accountData);
    updatedData['biometricEnabled'] = value;
    widget.onAccountUpdated(updatedData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value
            ? 'Biometric authentication enabled'
            : 'Biometric authentication disabled'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: EdgeInsets.all(3.w),
          child: CustomIconWidget(
            iconName: 'lock',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: CustomIconWidget(
            iconName: obscureText ? 'visibility' : 'visibility_off',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'account_circle',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Account Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // School Code Display
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'school',
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'School Code',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      widget.accountData['schoolCode'] as String? ?? 'SCH001',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text: widget.accountData['schoolCode'] as String? ??
                            'SCH001'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('School code copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: CustomIconWidget(
                    iconName: 'copy',
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Password Change Section
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'lock',
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  title: Text(
                    'Change Password',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  subtitle: Text(
                    'Update your account password',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: CustomIconWidget(
                    iconName:
                        _showPasswordFields ? 'expand_less' : 'expand_more',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  onTap: _togglePasswordChange,
                ),
                if (_showPasswordFields) ...[
                  Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        _buildPasswordField(
                          controller: _currentPasswordController,
                          label: 'Current Password',
                          obscureText: _obscureCurrentPassword,
                          onToggleVisibility: () => setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          }),
                        ),
                        SizedBox(height: 2.h),
                        _buildPasswordField(
                          controller: _newPasswordController,
                          label: 'New Password',
                          obscureText: _obscureNewPassword,
                          onToggleVisibility: () => setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          }),
                        ),
                        SizedBox(height: 2.h),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirm New Password',
                          obscureText: _obscureConfirmPassword,
                          onToggleVisibility: () => setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          }),
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _togglePasswordChange,
                                child: Text('Cancel'),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _changePassword,
                                child: Text('Update'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Biometric Authentication
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'fingerprint',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biometric Authentication',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Use fingerprint or face recognition to login',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
