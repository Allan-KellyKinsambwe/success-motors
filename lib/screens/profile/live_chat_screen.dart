// lib/screens/profile/live_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For better time formatting

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final String chatRoomId = 'support_chat_${_auth.currentUser!.uid}';

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePresence(isOnline: true, isTyping: false);
    _messageController.addListener(_onTypingChanged);
  }

  void _onTypingChanged() {
    final bool isTyping = _messageController.text.trim().isNotEmpty;
    _firestore.collection('live_chats').doc(chatRoomId).set({
      'userTyping': isTyping,
    }, SetOptions(merge: true));
  }

  void _updatePresence({required bool isOnline, bool isTyping = false}) {
    _firestore.collection('live_chats').doc(chatRoomId).set({
      'userOnline': isOnline,
      'userTyping': isTyping,
      'lastSeenUser': isOnline ? null : FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Mark unread support messages as read when user opens the chat
  Future<void> _markMessagesAsRead() async {
    try {
      final messagesRef = _firestore
          .collection('live_chats')
          .doc(chatRoomId)
          .collection('messages')
          .where('isSupport', isEqualTo: true)
          .where('read', isEqualTo: false);

      final snapshot = await messagesRef.get();
      if (snapshot.docs.isEmpty) return;

      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Send message
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String message = _messageController.text.trim();
    _messageController.clear();

    final String userId = _auth.currentUser!.uid;
    final String userName = _auth.currentUser!.displayName ?? 'User';
    final bool isSupport = false;

    final DocumentReference chatRoomRef = _firestore
        .collection('live_chats')
        .doc(chatRoomId);

    try {
      WriteBatch batch = _firestore.batch();

      DocumentReference messageRef = chatRoomRef.collection('messages').doc();
      batch.set(messageRef, {
        'text': message,
        'userId': userId,
        'userName': userName,
        'isSupport': isSupport,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'delivered': true, // Message reached server
      });

      batch.set(chatRoomRef, {
        'lastMessage': message,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'userName': userName,
        'unreadCount': FieldValue.increment(1),
        'supportTyping': false, // Clear typing when sending
      }, SetOptions(merge: true));

      await batch.commit();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatLastSeen(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'today at ${DateFormat('h:mm a').format(date)}';
    return DateFormat('d MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('live_chats')
              .doc(chatRoomId)
              .snapshots(),
          builder: (context, snapshot) {
            String status = 'Support';
            if (snapshot.hasData) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final bool supportOnline = data?['supportOnline'] ?? false;
              final bool supportTyping = data?['supportTyping'] ?? false;
              final Timestamp? lastSeen =
                  data?['lastSeenSupport'] as Timestamp?;

              if (supportTyping) {
                status = 'Typing...';
              } else if (supportOnline) {
                status = 'Online';
              } else if (lastSeen != null) {
                status = 'Last seen ${_formatLastSeen(lastSeen.toDate())}';
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Chat Support',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  status,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('live_chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Start a conversation with support!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final bool isMe = data['userId'] == _auth.currentUser!.uid;

                    final Timestamp? ts = data['timestamp'] as Timestamp?;
                    final DateTime time = ts?.toDate() ?? DateTime.now();
                    final String timeStr = DateFormat('h:mm a').format(time);

                    final bool delivered = data['delivered'] ?? false;
                    final bool read = data['read'] ?? false;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    delivered
                                        ? (read
                                              ? Icons.done_all
                                              : Icons.done_all)
                                        : Icons.done,
                                    size: 14,
                                    color: read ? Colors.cyan : Colors.white70,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: const Color(0xFF2E7D32),
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _updatePresence(isOnline: false);
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
