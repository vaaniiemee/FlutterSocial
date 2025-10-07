import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/error_widget.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final String? chatId;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userData,
    this.chatId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentChatId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (widget.chatId != null) {
      setState(() {
        _currentChatId = widget.chatId;
      });
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Check if chat already exists
      final existingChats = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (final chat in existingChats.docs) {
        final participants = List<String>.from(chat.data()['participants'] ?? []);
        if (participants.contains(widget.userId)) {
          setState(() {
            _currentChatId = chat.id;
          });
          return;
        }
      }

      // Create new chat
      final chatRef = await FirebaseFirestore.instance.collection('chats').add({
        'participants': [currentUserId, widget.userId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {currentUserId: 0, widget.userId: 0},
      });

      setState(() {
        _currentChatId = chatRef.id;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentChatId == null) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      // Add message to messages subcollection
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_currentChatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      // Update chat document
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_currentChatId)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {
          currentUserId: 0,
          widget.userId: FieldValue.increment(1),
        },
      });

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentChatId == null) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: _buildAppBar(),
        body: const Center(
          child: Text('Error: Could not initialize chat'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
            backgroundImage: widget.userData['photoURL'] != null
                ? NetworkImage(widget.userData['photoURL'] as String)
                : null,
            child: widget.userData['photoURL'] == null
                ? Text(
                    (widget.userData['name'] ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.fontSizeLarge,
                      fontWeight: AppConstants.fontWeightSemiBold,
                      color: AppConstants.primaryColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userData['name'] ?? 'Unknown User',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeLarge,
                    fontWeight: AppConstants.fontWeightSemiBold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Text(
                  'Online',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeSmall,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppConstants.backgroundColor,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Add call functionality
          },
          icon: const Icon(Icons.call),
        ),
        IconButton(
          onPressed: () {
            // TODO: Add video call functionality
          },
          icon: const Icon(Icons.videocam),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(_currentChatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return CustomErrorWidget(
            message: 'Error loading messages: ${snapshot.error}',
            onRetry: () => setState(() {}),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeLarge,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation!',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeMedium,
                    color: AppConstants.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final message = snapshot.data!.docs[index];
            final messageData = message.data() as Map<String, dynamic>;
            return _buildMessageBubble(messageData);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isMe = messageData['senderId'] == currentUserId;
    final timestamp = messageData['timestamp'] as Timestamp?;
    final time = timestamp?.toDate();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
              backgroundImage: widget.userData['photoURL'] != null
                  ? NetworkImage(widget.userData['photoURL'] as String)
                  : null,
              child: widget.userData['photoURL'] == null
                  ? Text(
                      (widget.userData['name'] ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeSmall,
                        fontWeight: AppConstants.fontWeightSemiBold,
                        color: AppConstants.primaryColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isMe 
                    ? AppConstants.primaryColor 
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    messageData['text'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.fontSizeMedium,
                      color: isMe ? Colors.white : AppConstants.textPrimary,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(time),
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeSmall,
                        color: isMe 
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppConstants.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
              backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                  ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                  : null,
              child: FirebaseAuth.instance.currentUser?.photoURL == null
                  ? Text(
                      (FirebaseAuth.instance.currentUser?.displayName ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeSmall,
                        fontWeight: AppConstants.fontWeightSemiBold,
                        color: AppConstants.primaryColor,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomTextField(
              controller: _messageController,
              hintText: 'Type a message...',
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month}';
    } else if (difference.inHours > 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return 'now';
    }
  }
}
