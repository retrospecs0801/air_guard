// =============================================================================
// FILE: lib/community/community_screen.dart
// Single file implementation for Community feature
// =============================================================================

import 'package:flutter/material.dart';

// =============================================================================
// DATA MODEL
// =============================================================================
class CommunityMessage {
  final String id;
  final String userName;
  final String userAvatar;
  final String message;
  final DateTime timestamp;
  final bool isCurrentUser;

  CommunityMessage({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.message,
    required this.timestamp,
    this.isCurrentUser = false,
  });

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}';
  }
}

// =============================================================================
// MOCK DATA SERVICE
// =============================================================================
class _MessageService {
  static List<CommunityMessage> _messages = [];

  static List<CommunityMessage> getMessages() {
    if (_messages.isEmpty) _initializeMockData();
    return List.from(_messages.reversed);
  }

  static void addMessage(String text) {
    _messages.add(CommunityMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: 'You',
      userAvatar: '😊',
      message: text,
      timestamp: DateTime.now(),
      isCurrentUser: true,
    ));
  }

  static void _initializeMockData() {
    final now = DateTime.now();
    _messages = [
      CommunityMessage(
        id: '1',
        userName: 'Priya Sharma',
        userAvatar: '👩',
        message: 'The air quality in Gomti Nagar is terrible today. My kids couldn\'t play outside. We need better monitoring systems!',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      CommunityMessage(
        id: '2',
        userName: 'Rahul Verma',
        userAvatar: '👨',
        message: 'I\'ve started using N95 masks daily. It helps a lot. Also doing breathing exercises from this app!',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      CommunityMessage(
        id: '3',
        userName: 'Anjali Singh',
        userAvatar: '👧',
        message: 'Does anyone know if the government is planning to increase green cover? We desperately need more trees in our area.',
        timestamp: now.subtract(const Duration(hours: 8)),
      ),
      CommunityMessage(
        id: '4',
        userName: 'Amit Kumar',
        userAvatar: '🧑',
        message: 'Saw heavy smoke near Alambagh today. Industrial emissions are getting worse. Someone should report this.',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      CommunityMessage(
        id: '5',
        userName: 'Neha Gupta',
        userAvatar: '👩‍💼',
        message: 'My elderly parents are struggling with the pollution. What recovery methods work best for seniors?',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      CommunityMessage(
        id: '6',
        userName: 'Vikram Yadav',
        userAvatar: '👨‍💼',
        message: 'We should organize a community plantation drive this weekend. Who\'s interested?',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      CommunityMessage(
        id: '7',
        userName: 'Sunita Devi',
        userAvatar: '👵',
        message: 'Indoor air purifiers helped my family a lot. Also keeping windows closed during peak pollution hours.',
        timestamp: now.subtract(const Duration(days: 2, hours: 5)),
      ),
      CommunityMessage(
        id: '8',
        userName: 'Rohan Mishra',
        userAvatar: '🧔',
        message: 'This app is really helpful! The recovery tracker motivated me to take pollution seriously.',
        timestamp: now.subtract(const Duration(days: 3)),
      ),
    ];
  }
}

// =============================================================================
// MAIN COMMUNITY SCREEN
// =============================================================================
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late List<CommunityMessage> _messages;
  final _textController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _messages = _MessageService.getMessages();
    _textController.addListener(() {
      setState(() => _hasText = _textController.text.trim().isNotEmpty);
    });
  }

  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _MessageService.addMessage(text);
        _messages = _MessageService.getMessages();
        _textController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message posted to community!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildMessageList()),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  // Header widget
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                'Community',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Let\'s create a community to discuss the effects and make our city better',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.95),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Share your views and concerns',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Message list
  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text('No messages yet. Start the conversation!'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  // Individual message bubble
  Widget _buildMessageBubble(CommunityMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: message.isCurrentUser
                ? Colors.green.shade200
                : Colors.blue.shade100,
            child: Text(message.userAvatar, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.formattedTime,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isCurrentUser
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: message.isCurrentUser
                          ? Colors.green.shade200
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Message input field
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Share your thoughts...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _hasText ? _handleSendMessage : null,
            backgroundColor: _hasText ? Colors.green : Colors.grey.shade300,
            child: const Icon(Icons.send, size: 20),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

