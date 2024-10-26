import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:incampus/student/chat_page.dart';

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    DatabaseEvent friendsEvent =
        await _database.child('users/$_currentUserId/friends').once();
    if (friendsEvent.snapshot.value != null) {
      Map<dynamic, dynamic> friends =
          friendsEvent.snapshot.value as Map<dynamic, dynamic>;
      List<Future<Map<String, dynamic>>> friendDataFutures = [];

      friends.forEach((friendId, _) {
        friendDataFutures.add(_loadFriendData(friendId));
      });

      List<Map<String, dynamic>> friendsData =
          await Future.wait(friendDataFutures);
      setState(() {
        _friends = friendsData;
      });
    }
  }

  Future<Map<String, dynamic>> _loadFriendData(String friendId) async {
    DatabaseEvent userEvent = await _database.child('users/$friendId').once();
    Map<String, dynamic> userData =
        Map<String, dynamic>.from(userEvent.snapshot.value as Map);

    DatabaseEvent lastMessageEvent = await _database
        .child('messages')
        .child(_currentUserId)
        .child(friendId)
        .limitToLast(1)
        .once();
    Map<String, dynamic>? lastMessage;
    if (lastMessageEvent.snapshot.value != null) {
      lastMessage = Map<String, dynamic>.from(
          (lastMessageEvent.snapshot.value as Map).values.first);
    }

    return {
      'id': friendId,
      'name': userData['name'],
      'profilePicture': userData['profilePicture'],
      'lastMessage': lastMessage?['text'] ?? '',
      'timestamp': lastMessage?['timestamp'] ?? 0,
      'unreadCount': await _getUnreadCount(friendId),
    };
  }

  Future<int> _getUnreadCount(String friendId) async {
    DatabaseEvent unreadEvent = await _database
        .child('messages')
        .child(_currentUserId)
        .child(friendId)
        .orderByChild('read')
        .equalTo(false)
        .once();
    return unreadEvent.snapshot.children.length;
  }

  void _openChat(Map<String, dynamic> friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(friend: friend),
      ),
    ).then((_) => _loadFriends());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          'Chats',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(friend['profilePicture']),
            ),
            title: Text(
              friend['name'],
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              friend['lastMessage'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getTimeAgo(friend['timestamp']),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (friend['unreadCount'] > 0)
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      friend['unreadCount'].toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            onTap: () => _openChat(friend),
          );
        },
      ),
    );
  }

  String _getTimeAgo(int timestamp) {
    final now = DateTime.now();
    final difference =
        now.difference(DateTime.fromMillisecondsSinceEpoch(timestamp));

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}
