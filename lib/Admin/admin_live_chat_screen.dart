// lib/Admin/admin_live_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminLiveChatScreen extends StatefulWidget {
  final String chatRoomId;
  const AdminLiveChatScreen({super.key, required this.chatRoomId});

  @override
  State<AdminLiveChatScreen> createState() => _AdminLiveChatScreenState();
}

class _AdminLiveChatScreenState extends State<AdminLiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final CollectionReference messagesRef = _firestore
      .collection('live_chats')
      .doc(widget.chatRoomId)
      .collection('messages');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePresence(isOnline: true, isTyping: false);
    _messageController.addListener(_onTypingChanged);
  }

  void _onTypingChanged() {
    final bool isTyping = _messageController.text.trim().isNotEmpty;
    _firestore.collection('live_chats').doc(widget.chatRoomId).set({
      'supportTyping': isTyping,
    }, SetOptions(merge: true));
  }

  void _updatePresence({required bool isOnline, bool isTyping = false}) {
    _firestore.collection('live_chats').doc(widget.chatRoomId).set({
      'supportOnline': isOnline,
      'supportTyping': isTyping,
      'lastSeenSupport': isOnline ? null : FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final unread = await messagesRef
          .where('isSupport', isEqualTo: false)
          .where('read', isEqualTo: false)
          .get();
      WriteBatch batch = _firestore.batch();
      for (var doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      await _firestore.collection('live_chats').doc(widget.chatRoomId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String message = _messageController.text.trim();
    _messageController.clear();

    final DocumentReference chatRoomRef = _firestore
        .collection('live_chats')
        .doc(widget.chatRoomId);

    try {
      WriteBatch batch = _firestore.batch();

      DocumentReference messageRef = messagesRef.doc();
      batch.set(messageRef, {
        'text': message,
        'userId': 'admin',
        'userName': 'Support',
        'isSupport': true,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'delivered': true,
      });

      batch.set(chatRoomRef, {
        'lastMessage': message,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'userTyping': false,
      }, SetOptions(merge: true));

      await batch.commit();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send')));
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
    final diff = DateTime.now().difference(date);
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
              .doc(widget.chatRoomId)
              .snapshots(),
          builder: (context, snapshot) {
            String userName = 'User';
            String status = 'Offline';

            if (snapshot.hasData) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              userName = data?['userName'] ?? 'User';
              final bool userOnline = data?['userOnline'] ?? false;
              final bool userTyping = data?['userTyping'] ?? false;
              final Timestamp? lastSeen = data?['lastSeenUser'] as Timestamp?;

              if (userTyping) {
                status = 'Typing...';
              } else if (userOnline) {
                status = 'Online';
              } else if (lastSeen != null) {
                status = 'Last seen ${_formatLastSeen(lastSeen.toDate())}';
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
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
              stream: messagesRef.orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData)
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  );

                final messages = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                if (messages.isEmpty)
                  return const Center(
                    child: Text(
                      'Start replying to the user',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final bool isSupport = data['isSupport'] ?? false;

                    final Timestamp? ts = data['timestamp'] as Timestamp?;
                    final DateTime time = ts?.toDate() ?? DateTime.now();
                    final String timeStr = DateFormat('h:mm a').format(time);

                    final bool delivered = data['delivered'] ?? false;
                    final bool read = data['read'] ?? false;

                    return Align(
                      alignment: isSupport
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
                          color: isSupport
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: isSupport
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                color: isSupport
                                    ? Colors.white
                                    : Colors.black87,
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
                                    color: isSupport
                                        ? Colors.white70
                                        : Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                                if (isSupport) ...[
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
                    decoration: InputDecoration(
                      hintText: "Type a reply...",
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
