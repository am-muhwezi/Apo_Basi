import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/busminder_drawer_widget.dart';

class BusminderCommunicationsScreen extends StatefulWidget {
  const BusminderCommunicationsScreen({super.key});

  @override
  State<BusminderCommunicationsScreen> createState() =>
      _BusminderCommunicationsScreenState();
}

class _BusminderCommunicationsScreenState
    extends State<BusminderCommunicationsScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String _selectedRecipient = 'School Admin';

  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      // Load mock messages (replace with API call)
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        _messages = [
          {
            'id': 1,
            'from': 'School Admin',
            'message': 'Please ensure all students are accounted for today.',
            'timestamp': '10:30 AM',
            'isRead': true,
            'isIncoming': true,
          },
          {
            'id': 2,
            'from': 'Me',
            'message': 'Understood. All students checked in.',
            'timestamp': '10:35 AM',
            'isRead': true,
            'isIncoming': false,
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add({
        'id': _messages.length + 1,
        'from': 'Me',
        'message': message,
        'timestamp': TimeOfDay.now().format(context),
        'isRead': true,
        'isIncoming': false,
      });
    });

    // TODO: Send via API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message sent to $_selectedRecipient'),
        backgroundColor: AppTheme.successAction,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isIncoming = message['isIncoming'] ?? false;

    return Align(
      alignment: isIncoming ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
        padding: EdgeInsets.all(3.w),
        constraints: BoxConstraints(maxWidth: 75.w),
        decoration: BoxDecoration(
          gradient: isIncoming
              ? null
              : LinearGradient(
                  colors: [
                    AppTheme.primaryBusminder,
                    AppTheme.primaryBusminderLight,
                  ],
                ),
          color: isIncoming ? AppTheme.backgroundSecondary : null,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(isIncoming ? 4 : 16),
            bottomRight: Radius.circular(isIncoming ? 16 : 4),
          ),
          border: isIncoming
              ? Border.all(color: AppTheme.borderLight, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: (isIncoming
                      ? AppTheme.borderLight
                      : AppTheme.primaryBusminder)
                  .withValues(alpha: 0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isIncoming)
              Text(
                message['from'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBusminder,
                ),
              ),
            if (isIncoming) SizedBox(height: 0.5.h),
            Text(
              message['message'] ?? '',
              style: TextStyle(
                fontSize: 15,
                color: isIncoming ? AppTheme.textPrimary : Colors.white,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              message['timestamp'] ?? '',
              style: TextStyle(
                fontSize: 11,
                color: isIncoming
                    ? AppTheme.textSecondary
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBusminder.withValues(alpha: 0.1),
                AppTheme.primaryBusminderLight.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBusminder.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryBusminder, size: 28),
              SizedBox(height: 0.5.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'Communications',
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: AppTheme.primaryBusminder,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.person, color: Colors.white),
            onSelected: (value) {
              setState(() => _selectedRecipient = value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Recipient: $value'),
                  backgroundColor: AppTheme.primaryBusminder,
                ),
              );
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'School Admin', child: Text('School Admin')),
              PopupMenuItem(value: 'Driver', child: Text('Driver')),
              PopupMenuItem(
                  value: 'Parents', child: Text('Parents (Broadcast)')),
            ],
          ),
        ],
      ),
      drawer: const BusminderDrawerWidget(
          currentRoute: '/busminder-communications'),
      body: Column(
        children: [
          // Quick Actions
          Container(
            padding: EdgeInsets.all(4.w),
            color: AppTheme.backgroundSecondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    _buildQuickActionButton(
                      icon: Icons.emergency,
                      label: 'Emergency',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Row(
                              children: [
                                Icon(Icons.warning,
                                    color: AppTheme.criticalAlert),
                                SizedBox(width: 2.w),
                                Text('Emergency Alert'),
                              ],
                            ),
                            content: Text(
                              'This will send an emergency alert to the school admin. Use only in case of emergency.',
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
                                      content: Text('Emergency alert sent!'),
                                      backgroundColor: AppTheme.criticalAlert,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.criticalAlert,
                                ),
                                child: Text('Send Alert'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 3.w),
                    _buildQuickActionButton(
                      icon: Icons.phone,
                      label: 'Call Admin',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Calling school admin...'),
                            backgroundColor: AppTheme.successAction,
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 3.w),
                    _buildQuickActionButton(
                      icon: Icons.report,
                      label: 'Report Issue',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Report issue form coming soon'),
                            backgroundColor: AppTheme.primaryBusminder,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.borderLight),

          // Messages List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color:
                                  AppTheme.textSecondary.withValues(alpha: 0.3),
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
                              'Send a message to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              border: Border(
                top: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message to $_selectedRecipient...',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: AppTheme.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: AppTheme.primaryBusminder,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundPrimary,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.5.h,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                SizedBox(width: 2.w),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBusminder,
                        AppTheme.primaryBusminderLight,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
