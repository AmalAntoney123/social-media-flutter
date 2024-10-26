import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> friend;

  ChatPage({required this.friend});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
  }

  void _loadMessages() {
    _database
        .child('messages')
        .child(_currentUserId)
        .child(widget.friend['id'])
        .onChildAdded
        .listen((event) {
      setState(() {
        _messages.insert(
            0, Map<String, dynamic>.from(event.snapshot.value as Map));
      });
    });
  }

  void _markMessagesAsRead() {
    _database
        .child('messages')
        .child(_currentUserId)
        .child(widget.friend['id'])
        .orderByChild('read')
        .equalTo(false)
        .once()
        .then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> unreadMessages =
            event.snapshot.value as Map<dynamic, dynamic>;
        unreadMessages.forEach((key, value) {
          _database
              .child('messages')
              .child(_currentUserId)
              .child(widget.friend['id'])
              .child(key)
              .update({'read': true});
        });
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final message = {
        'senderId': _currentUserId,
        'text': _messageController.text,
        'timestamp': timestamp,
        'read': false,
      };

      _database
          .child('messages')
          .child(_currentUserId)
          .child(widget.friend['id'])
          .push()
          .set(message);

      _database
          .child('messages')
          .child(widget.friend['id'])
          .child(_currentUserId)
          .push()
          .set(message);

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          widget.friend['name'],
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser = message['senderId'] == _currentUserId;
                return _buildMessageBubble(message, isCurrentUser);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isCurrentUser) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7),
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.blue : Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'],
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(message['timestamp']),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      SizedBox(width: 4),
                      if (isCurrentUser) _buildReadReceipt(message['read']),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadReceipt(bool isRead) {
    return Icon(
      isRead ? Icons.done_all : Icons.done,
      size: 16,
      color: isRead ? const Color.fromARGB(255, 21, 133, 30) : Colors.grey[400],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat.jm().format(date);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}
