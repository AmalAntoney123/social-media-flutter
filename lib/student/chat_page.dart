import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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
  }

  void _loadMessages() {
    _database
        .child('messages')
        .child(_currentUserId)
        .child(widget.friend['id'])
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _messages.insert(
              0, Map<String, dynamic>.from(event.snapshot.value as Map));
        });
      }
    });

    // Mark messages as read for the current user
    _database
        .child('messages')
        .child(_currentUserId)
        .child(widget.friend['id'])
        .orderByChild(_currentUserId == widget.friend['id']
            ? 'senderRead'
            : 'receiverRead')
        .equalTo(false)
        .once()
        .then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> unreadMessages =
            event.snapshot.value as Map<dynamic, dynamic>;
        unreadMessages.forEach((key, value) {
          print('Updating message: $key');
          print(
              'Current user is ${_currentUserId == widget.friend['id'] ? "sender" : "receiver"}');

          _database
              .child('messages')
              .child(_currentUserId)
              .child(widget.friend['id'])
              .child(key)
              .update({
            _currentUserId == widget.friend['id']
                ? 'senderRead'
                : 'receiverRead': true
          });

          // Update the same message in the friend's node
          _database
              .child('messages')
              .child(widget.friend['id'])
              .child(_currentUserId)
              .child(key)
              .update({
            _currentUserId == widget.friend['id']
                ? 'senderRead'
                : 'receiverRead': true
          });
          print('Update complete');
        });
      } else {
        print('No unread messages found');
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      final message = {
        'senderId': _currentUserId,
        'receiverId': widget.friend['id'],
        'text': _messageController.text,
        'timestamp': ServerValue.timestamp,
        'senderRead': true,
        'receiverRead': false,
        'sent': true,
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

  Widget _buildMessageStatus(bool sent, bool senderRead, bool receiverRead) {
    if (!sent) {
      return Icon(Icons.access_time, size: 16, color: Colors.grey[400]);
    } else if (senderRead && receiverRead) {
      return Icon(Icons.done_all, size: 16, color: Colors.blue[300]);
    } else {
      return Icon(Icons.done, size: 16, color: Colors.grey[400]);
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
                return Align(
                  alignment: isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color:
                          isCurrentUser ? Colors.blue[700] : Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          message['text'],
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        if (isCurrentUser)
                          _buildMessageStatus(message['sent'],
                              message['senderRead'], message['receiverRead']),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      filled: true,
                      fillColor: Colors.grey[800],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  color: Colors.blue,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
