import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:untitled4/components/context-extenssion.dart';

class PrivetChatScreen extends StatefulWidget {
  final String userEmail;

  const PrivetChatScreen({required this.userEmail, super.key});

  @override
  _PrivetChatScreenState createState() => _PrivetChatScreenState();
}

class _PrivetChatScreenState extends State<PrivetChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final User? admin = FirebaseAuth.instance.currentUser;
  bool _isEmojiVisible = false;
  final ScrollController _scrollController = ScrollController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();


  @override
  void initState() {
    super.initState();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.listenToMessages(admin?.email ?? '', widget.userEmail);
    chatProvider.resetReceivedMessagesCount();
    _scrollToBottom();
  }

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    final time = Timestamp.now();

    final admin = this.admin;
    if (admin != null) {
      String receiverEmail = widget.userEmail;

      if (receiverEmail == admin.email) {
        receiverEmail = admin.email ?? '';
      }

      // إضافة الرسالة إلى Firestore
      await FirebaseFirestore.instance.collection('chat_p').add({
        'sender': admin.email,
        'receiver': receiverEmail,
        'message': message,
        'timestamp': time,
        'isNewMessage': true,
      });

      // حفظ الرسالة في قائمة الرسائل المرسلة في ChatProvider
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.addSentMessage(message, receiverEmail, time);

      // تحديث عداد الرسائل المرسلة
      chatProvider.updateMessageCounts(
        chatProvider.sentMessagesCount + 1,
        chatProvider.receivedMessagesCount,
      );
    }

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> showNotification(String message, String sender) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'New message from $sender',
      message,
      platformChannelSpecifics,
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }



  void _toggleEmojiPicker() {
    if (mounted) {
      setState(() {
        _isEmojiVisible = !_isEmojiVisible;
      });
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    _messageController.text += emoji.emoji;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${context.localizations.chat_with} ${widget.userEmail}',
              style: TextStyle(
                  color: Colors.yellow[700], fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),

            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return Text(
                  '${context.localizations.send}: ${chatProvider.sentMessagesCount}',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
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
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chat_p')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No messages yet!'));
                      }

                      final messages = snapshot.data!.docs;

                      for (var message in messages) {
                        final messageData =
                        message.data() as Map<String, dynamic>;
                        if (messageData['isNewMessage'] == true &&
                            messageData['receiver'] == admin?.email) {
                          showNotification(
                              messageData['message'], messageData['sender']);
                          FirebaseFirestore.instance
                              .collection('chat_p')
                              .doc(message.id)
                              .update({'isNewMessage': false});
                        }
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final messageData =
                          messages[index].data() as Map<String, dynamic>;

                          bool isSender =
                              messageData['sender'] == widget.userEmail;
                          bool isReceiver =
                              messageData['receiver'] == widget.userEmail;

                          if (isSender || isReceiver) {
                            bool isMe =
                                messageData['sender'] == widget.userEmail;

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 14),
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.yellow[700]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  messageData['message'],
                                  style: TextStyle(
                                      color:
                                      isMe ? Colors.white : Colors.black),
                                ),
                              ),
                            );
                          }

                          return Container();
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
                      config: const Config(),
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
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Tooltip(message: 'اموجي',
                          child: IconButton(
                          icon: Icon(Icons.emoji_emotions,
                              color: Colors.yellow[700]),
                          onPressed: _toggleEmojiPicker,
                        ),
                        ),

                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration:  InputDecoration(
                              hintText: context.localizations.enter_your_message,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) {
                              sendMessage();
                            },
                          ),
                        ),
                        Tooltip(
                          message: 'ارسل',
                          child:  IconButton(
                            icon: Icon(Icons.send, color: Colors.yellow[700]),
                            onPressed: sendMessage,
                          ),
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
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 70), // تحريك الزر للأعلى بمقدار 50 بكسل
        child:Tooltip(
          message: 'انتقل الى الاسفل',
    child:
        FloatingActionButton(
          onPressed: _scrollToBottom,
          backgroundColor: Colors.transparent,
          child: Icon(Icons.arrow_downward, color: Colors.black),
        ),
        ),
      ),


    );
  }
}

class ChatProvider with ChangeNotifier {
  int _sentMessagesCount = 0;
  int _receivedMessagesCount = 0;
  List<Map<String, dynamic>> _sentMessages = [];

  int get sentMessagesCount => _sentMessagesCount;
  int get receivedMessagesCount => _receivedMessagesCount;

  List<Map<String, dynamic>> get sentMessages => _sentMessages;

  Future<void> loadMessageCounts() async {
    final prefs = await SharedPreferences.getInstance();
    _sentMessagesCount = prefs.getInt('sent_messages_count') ?? 0;
    _receivedMessagesCount = prefs.getInt('received_messages_count') ?? 0;
    notifyListeners();
  }

  Future<void> updateMessageCounts(int sentCount, int receivedCount) async {
    final prefs = await SharedPreferences.getInstance();
    _sentMessagesCount = sentCount;
    _receivedMessagesCount = receivedCount;
    await prefs.setInt('sent_messages_count', _sentMessagesCount);
    await prefs.setInt('received_messages_count', _receivedMessagesCount);
    notifyListeners();
  }

  void addSentMessage(String message, String receiver, Timestamp timestamp) {
    _sentMessages.add({
      'message': message,
      'receiver': receiver,
      'timestamp': timestamp,
    });
    notifyListeners();
  }

  void listenToMessages(String currentUserEmail, String otherUserEmail) {
    FirebaseFirestore.instance
        .collection('chat_p')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) async {
      int sentMessages = 0;
      int receivedMessages = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['sender'] == currentUserEmail &&
            data['receiver'] == otherUserEmail) {
          sentMessages++;
        }

        if (data['receiver'] == otherUserEmail &&
            data['sender'] == otherUserEmail) {
          receivedMessages++;
        }
      }

      if (sentMessages != _sentMessagesCount ||
          receivedMessages != _receivedMessagesCount) {
        await updateMessageCounts(sentMessages, receivedMessages);
      }
    });
  }

  Future<void> clearMessageCounts() async {
    _sentMessagesCount = 0;
    _receivedMessagesCount = 0;
    _sentMessages.clear();
    notifyListeners();
  }

  Future<void> resetReceivedMessagesCount() async {
    _receivedMessagesCount = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('received_messages_count', _receivedMessagesCount);
    notifyListeners();
  }
}