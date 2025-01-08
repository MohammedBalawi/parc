import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:untitled4/components/context-extenssion.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  bool _isEmojiVisible = false;
  String? _userName;
  final ScrollController _scrollController = ScrollController();
  int? totalUsersCount;

  @override
  void initState() {
    super.initState();
    _getUserName();
    _initializeNotifications();
    _listenForMessages();
    _fetchTotalUsersCount();

  }
  Future<int> getTotalUsersCount() async {
    final userCollection = await FirebaseFirestore.instance.collection('users').get();
    return userCollection.docs.length;
  }

  Future<void> _fetchTotalUsersCount() async {
    totalUsersCount = await getTotalUsersCount();
    setState(() {});
  }
  Future<void> _getUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      final profileSnapshot = await _firestore
          .collection('profiles')
          .where('email', isEqualTo: user.email)
          .get();

      if (profileSnapshot.docs.isNotEmpty) {
        setState(() {
          _userName = profileSnapshot.docs.first['name']; // استرجاع الاسم
        });
      }
    }
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    _notificationsPlugin.initialize(initializationSettings);
  }

  // void _listenForMessages() {
  //   FirebaseFirestore.instance.collection('messages').snapshots().listen((snapshot) {
  //     for (var change in snapshot.docChanges) {
  //       if (change.type == DocumentChangeType.added) {
  //         final data = change.doc.data() as Map<String, dynamic>;
  //         if (data['sender'] != _auth.currentUser?.email) {
  //           _showNotification(data['senderName'] ?? 'New Message', data['text']);
  //         }
  //       }
  //     }
  //   });
  // }

  void _listenForMessages() {
    _firestore.collection('messages').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          final messageId = change.doc.id;


        }
      }
    });
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'message_channel',
      'Message Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _sendMessage({String? url, String type = 'text'}) async {
    if (_controller.text.isNotEmpty || url != null) {
      await _firestore.collection('messages').add({
        'text': url ?? _controller.text,
        'sender': _auth.currentUser?.email,
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
        'senderName': _userName ?? _auth.currentUser?.email,
        'readBy': [], // حقل readBy فارغ عند إرسال الرسالة
      });
      _controller.clear();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiVisible = !_isEmojiVisible;
    });
  }

  void _onEmojiSelected(Emoji emoji) {
    _controller.text += emoji.emoji;
  }

  Future<bool> checkIfUserIsAdmin() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final doc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data()?['isAdmin'] ?? false;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          context.localizations.chat_group,
          style: TextStyle(
            color: Colors.yellow[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.people),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserList()),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5),
                ],
              ),
              child: IconButton(
                onPressed: () async {
                  bool isAdmin = await checkIfUserIsAdmin();
                  if (isAdmin) {
                    Navigator.pushReplacementNamed(context, '/admin');
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                icon: Icon(Icons.arrow_forward_ios_outlined),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/image/parc.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(),
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final messages = snapshot.data!.docs;
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final data = message.data() as Map<String, dynamic>;
                          final isMe = data['sender'] == _auth.currentUser?.email;
                          final isReadByCurrentUser = (data['readBy'] ?? []).contains(_auth.currentUser?.email);

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.yellow[700]
                                    : isReadByCurrentUser
                                    ? Colors.grey[300]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['senderName'] ?? data['sender'],
                                    style: TextStyle(
                                      color: isMe ? Colors.white70 : Colors.black,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    data['text'],
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black,
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
                ),
                if (_isEmojiVisible)
                  SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        _onEmojiSelected(emoji);
                      },
                      config: Config(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.emoji_emotions,
                              color: Colors.yellow[700]),
                          onPressed: _toggleEmojiPicker,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration:  InputDecoration(
                              hintText: context.localizations.enter_your_message,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) {
                              _sendMessage();
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () => _sendMessage(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          context.localizations.user_profiles,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserProfiles(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15.0),
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Text(
                          user['name'] != null ? user['name'][0] : 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        user['email'] ?? 'No Email',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon:
                        const Icon(Icons.info_outline, color: Colors.teal),
                        onPressed: () {
                          _showUserDetails(user, context);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserProfiles() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collection('profiles').get();
    return querySnapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })
        .toList();
  }

  void _showUserDetails(Map<String, dynamic> user, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text(context.localizations.user_profiles),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('${context.localizations.name}: ${user['name'] ?? 'No Name'}'),
              Text('${context.localizations.email}: ${user['email'] ?? 'No Email'}'),
              Text('${context.localizations.phone}: ${user['phone'] ?? 'No Phone'}'),
              Text('${context.localizations.location}: ${user['city'] ?? 'No Location'}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:  Text(context.localizations.close),
            ),
          ],
        );
      },
    );
  }
}


