// lib/Admin/live_chats_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:success_motors/Admin/admin_live_chat_screen.dart';

class LiveChatsListScreen extends StatefulWidget {
  const LiveChatsListScreen({super.key});

  @override
  State<LiveChatsListScreen> createState() => _LiveChatsListScreenState();
}

class _LiveChatsListScreenState extends State<LiveChatsListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Live Chat Support',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('live_chats')
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // === ERROR HANDLING ===
          if (snapshot.hasError) {
            // Print full error to console (very helpful for index issues)
            debugPrint('Firestore Stream Error: ${snapshot.error}');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load chats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}), // Retry
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // === LOADING STATE ===
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          // === NO DATA ===
          final chatRooms = snapshot.data!.docs;

          if (chatRooms.isEmpty) {
            return const Center(
              child: Text(
                'No active chats yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // === SUCCESS: DISPLAY CHATS ===
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final data = chatRooms[index].data() as Map<String, dynamic>;
              final String chatRoomId = chatRooms[index].id;
              final String lastMessage =
                  data['lastMessage'] ?? 'No messages yet';
              final Timestamp? lastTimestamp =
                  data['lastTimestamp'] as Timestamp?;
              final int unreadCount =
                  (data['unreadCount'] as num?)?.toInt() ?? 0;

              final String userName = data['userName'] ?? 'Unknown User';

              final String timeStr = lastTimestamp != null
                  ? _formatTimestamp(lastTimestamp.toDate())
                  : '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminLiveChatScreen(chatRoomId: chatRoomId),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2E7D32),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return TimeOfDay.fromDateTime(date).format(context);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
