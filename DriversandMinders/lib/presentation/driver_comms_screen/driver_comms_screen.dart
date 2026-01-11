import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

class DriverCommsScreen extends StatefulWidget {
  const DriverCommsScreen({super.key});

  @override
  State<DriverCommsScreen> createState() => _DriverCommsScreenState();
}

class _DriverCommsScreenState extends State<DriverCommsScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'from': 'School Admin',
      'message': 'Please confirm receipt of today\'s route changes.',
      'time': '10:30 AM',
      'isRead': false,
      'isFromSchool': true,
    },
    {
      'from': 'You',
      'message': 'Route changes confirmed. Will follow new pickup schedule.',
      'time': '10:25 AM',
      'isRead': true,
      'isFromSchool': false,
    },
    {
      'from': 'School Admin',
      'message': 'Route update: Construction on Main St. Use alternate route.',
      'time': '9:15 AM',
      'isRead': true,
      'isFromSchool': true,
    },
  ];

  final List<Map<String, dynamic>> _quickMessages = [
    {
      'title': 'Running Late',
      'message': 'Bus is running 10-15 minutes behind schedule due to traffic.',
      'icon': Icons.schedule,
    },
    {
      'title': 'Route Delay',
      'message': 'Experiencing delays on the route. Will update ETA shortly.',
      'icon': Icons.traffic,
    },
    {
      'title': 'Vehicle Issue',
      'message': 'Minor vehicle issue. Handling it now. Students are safe.',
      'icon': Icons.build,
    },
    {
      'title': 'All Clear',
      'message': 'Everything is on schedule. All students picked up safely.',
      'icon': Icons.check_circle,
    },
  ];

  void _showNewMessageDialog() {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.message, color: AppTheme.primaryDriver),
            SizedBox(width: 2.w),
            Text('New Message'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your message to school admin...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final message = messageController.text.trim();
              if (message.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message sent to school admin'),
                    backgroundColor: AppTheme.successAction,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a message'),
                    backgroundColor: AppTheme.criticalAlert,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDriver,
            ),
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _sendQuickMessage(String message) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send this message to dispatch?'),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryDriver.withValues(alpha: 0.3)),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Message sent to dispatch'),
                  backgroundColor: AppTheme.successAction,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDriver,
            ),
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightDriverTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: CustomAppBar(
          title: 'Comms',
          subtitle: 'School Communication',
          actions: [
            IconButton(
              onPressed: _showNewMessageDialog,
              icon: Icon(Icons.add_comment, color: AppTheme.textOnPrimary),
              tooltip: 'New Message',
            ),
          ],
        ),
        body: Column(
          children: [
            // Info Banner
            Container(
              margin: EdgeInsets.all(4.w),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryDriver.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryDriver.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryDriver,
                    size: 20,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Communicate directly with school administration',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Start a conversation with school admin',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageCard(
                          from: message['from'] as String,
                          message: message['message'] as String,
                          time: message['time'] as String,
                          isRead: message['isRead'] as bool,
                          isFromSchool: message['isFromSchool'] as bool,
                        );
                      },
                    ),
            ),

            // Quick Messages Section
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowLight,
                    offset: Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Quick Messages',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: _quickMessages.map((msg) {
                      return _buildQuickMessageButton(
                        title: msg['title'] as String,
                        message: msg['message'] as String,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showNewMessageDialog,
          backgroundColor: AppTheme.primaryDriver,
          icon: Icon(Icons.message, color: AppTheme.textOnPrimary),
          label: Text(
            'New Message',
            style: TextStyle(
              color: AppTheme.textOnPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard({
    required String from,
    required String message,
    required String time,
    required bool isRead,
    required bool isFromSchool,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isFromSchool ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isFromSchool) ...[
            CircleAvatar(
              backgroundColor: AppTheme.primaryDriver.withValues(alpha: 0.1),
              child: Icon(
                Icons.school,
                color: AppTheme.primaryDriver,
                size: 20,
              ),
            ),
            SizedBox(width: 2.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isFromSchool
                    ? AppTheme.backgroundSecondary
                    : AppTheme.primaryDriver.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFromSchool
                      ? AppTheme.textSecondary.withValues(alpha: 0.2)
                      : AppTheme.primaryDriver.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        from,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isFromSchool ? AppTheme.primaryDriver : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (!isRead && isFromSchool) ...[
                    SizedBox(height: 0.5.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.criticalAlert,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'New',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isFromSchool) ...[
            SizedBox(width: 2.w),
            CircleAvatar(
              backgroundColor: AppTheme.primaryDriver,
              child: Icon(
                Icons.person,
                color: AppTheme.textOnPrimary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickMessageButton({
    required String title,
    required String message,
  }) {
    return ElevatedButton(
      onPressed: () => _sendQuickMessage(message),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryDriver.withValues(alpha: 0.1),
        foregroundColor: AppTheme.primaryDriver,
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
