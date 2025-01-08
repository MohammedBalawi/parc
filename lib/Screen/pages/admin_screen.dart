import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled4/components/context-extenssion.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/language_provider.dart';
import '../../components/shared.dart';
import '../../main.dart';
import '../Chat/privet_chat_screen.dart';
import '../Favorites/favorites_screen.dart';
import '../Files/file_screen.dart';
import '../Files/send_screen.dart';
import '../Files/upload_screen.dart';
import '../Invoice/send_invoice_screen.dart';
import '../map/map_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool hasNewNotification = false;
  List<String> notificationLog = [];
  late String _language;

  @override
  void initState() {
    super.initState();
    initNotifications();
    fetchNotifications();
    loadNotificationState();
    _language =
        SharedPrefController().getValueFor<String>(Key: PreKey.language.name) ??
            'en';
  }

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hasNewNotification = prefs.getBool('hasNewNotification') ?? false;
    });
  }

  Future<void> saveNotificationState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasNewNotification', state);
  }

  Future<void> showNotification(String fileName) async {
    User? user = FirebaseAuth.instance.currentUser;
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'upload_channel',
      'File Uploads',
      channelDescription: 'Channel for file upload notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Upload Successful',
      'File "$fileName" uploaded successfully.',
      platformChannelSpecifics,
    );

    FirebaseFirestore.instance.collection('notifications').add({
      'message': 'File "$fileName" uploaded successfully.',
      'email': user?.email,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      notificationLog.add('File "$fileName" uploaded successfully.');
      hasNewNotification = true;
    });

    await saveNotificationState(true);
  }

  void fetchNotifications() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        notificationLog =
            snapshot.docs.map((doc) => doc['message'] as String).toList();
      });
    });
  }

  void openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          notifications: notificationLog
              .map((notification) =>
                  {'title': 'Notification', 'description': notification})
              .toList(), // تحويل النصوص إلى خرائط
          onNotificationsViewed: () async {
            setState(() {
              hasNewNotification = false;
            });
            await saveNotificationState(false);
          },
        ),
      ),
    );
  }

  void logout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(context.localizations.logout),
          content: Text(context.localizations.logout_dialog_content),
          actions: [
            TextButton(
              child: Text(context.localizations.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(context.localizations.logout),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        );
      },
    );
  }

  void _showLanguageBottomSheet() async {
    String? languag = await showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(10),
          topEnd: Radius.circular(10),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      context: context,
      builder: (context) {
        return BottomSheet(
          onClosing: () {},
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.localizations.language_sheet_title,
                        style: TextStyle(
                            fontSize: 22,
                            // height: 1.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      Text(
                        context.localizations.language_sheet_subtitle,
                        style: TextStyle(
                            fontSize: 19,
                            // height: 1.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black12),
                      ),
                      Divider(),
                      RadioListTile<String>(
                          value: 'en',
                          title: Text('English', style: TextStyle(),),
                          groupValue: _language,
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _language = value;
                                Navigator.pop(context, 'en');
                              });
                            }
                          }),
                      RadioListTile<String>(
                          value: 'ar',
                          title: Text('العربية', style: TextStyle(),),
                          groupValue: _language,
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _language = value;
                                Navigator.pop(context, 'ar');
                              });
                            }
                          }),
                    ],
                  ),
                );
              },);
          },
        );
      },
    );
    if (languag != null) {
      Future.delayed(Duration(milliseconds: 700), () {
        Provider.of<LanguageProvider>(context, listen: false).changeLanguage();
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchAccounts() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('profiles').get();

    Map<String, Map<String, dynamic>> uniqueAccounts = {};

    for (var doc in snapshot.docs) {
      var accountData = doc.data() as Map<String, dynamic>;
      uniqueAccounts[accountData['email']] = accountData;
    }

    return uniqueAccounts.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: const DecorationImage(
            image: AssetImage('assets/image/parc.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0),
            ),
            child: Row(
              children: [
                // Sidebar
                Container(
                  width: 250,
                  child: Column(
                    children: [
                      const DrawerHeader(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Image(
                            width: 180,
                            height: 80,
                            image: AssetImage('assets/image/شعار مفرغ.png'),
                          ),
                        ),
                      ),
                      Tooltip(message: 'الدردشة الجماعية',
                      child:  _buildDrawerItem(
                        icon: Icons.chat,
                        title: context.localizations.chat,
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/chat');
                        },
                      ),
                      ),
                      Tooltip(message: 'الاعضاء',
                        child: _buildDrawerItem(
                          icon: Icons.supervised_user_circle,
                          title: context.localizations.accounts,
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/user');
                          },
                        ),
                      ),
                      Tooltip(message: 'الملفات',
                        child:   _buildDrawerItem(
                          icon: Icons.folder,
                          title: context.localizations.files,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => FileScreen()),
                            );
                          },
                        ),
                      ),
                      Tooltip(message: 'المفضله',
                        child:    _buildDrawerItem(
                          icon: Icons.favorite_outlined,
                          title: context.localizations.favorites,
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/FileUploadScreen');
                          },
                        ),
                      ),
                      Tooltip(message: 'اللغة',
                        child: _buildDrawerItem(
                          icon: Icons.language,
                          title: context.localizations.language,
                          onTap: () {
                            _showLanguageBottomSheet();
                          },
                        ),
                      ),

                    ],
                  ),
                ),
                // Main content
                Expanded(
                  child: Column(
                    children: [
                      // Header section
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        color: Colors.yellow[700],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    context.localizations.admin_dashboard,
                                    style: TextStyle(
                                      color: Colors.yellow[700],
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Stack(
                                    children: [
                                      Tooltip(message: 'الاشعارات',
                                        child: IconButton(
                                          icon: Icon(Icons.notifications,
                                              color: hasNewNotification
                                                  ? Colors.red
                                                  : Colors.white),
                                          onPressed: openNotifications,
                                        ),
                                      ),

                                      if (hasNewNotification)
                                        const Positioned(
                                          right: 11,
                                          top: 11,
                                          child: Icon(
                                            Icons.brightness_1,
                                            size: 8.0,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 5),
                                      ],
                                    ),
                                    child:   Tooltip(message: 'تسجيل الخروج',
                                      child:IconButton(
                                        icon: Icon(Icons.logout,
                                            color: Colors.yellow[700]),
                                        onPressed: () => logout(context),
                                      ),
                                    ),

                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      // Accounts list
                      Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: fetchAccounts(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return const Center(
                                  child: Text('Error loading accounts'));
                            } else {
                              final accounts = snapshot.data ?? [];
                              return ListView.builder(
                                itemCount: accounts.length,
                                itemBuilder: (context, index) {
                                  final account = accounts[index];
                                  return AccountTile(accountData: account);
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.yellow[700]),
      title: Text(title, style: TextStyle(color: Colors.yellow[700])),
      onTap: onTap,
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  final List<Map<String, String>> notifications;
  final VoidCallback onNotificationsViewed;

  const NotificationsScreen({
    super.key,
    required this.notifications,
    required this.onNotificationsViewed,
  });

  @override
  Widget build(BuildContext context) {
    // عند فتح الصفحة، سيتم تنفيذ الوظيفة للتحديث
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNotificationsViewed();
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'No Notifications!',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification['description'] ?? 'No Description',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class AccountTile extends StatelessWidget {
  final Map<String, dynamic> accountData;

  const AccountTile({
    required this.accountData,
    super.key,
  });

  Future<void> markMessagesAsRead(String email) async {
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('chat_p')
        .where('receiver', isEqualTo: email)
        .where('isNewMessage', isEqualTo: true)
        .get();

    for (var doc in messagesSnapshot.docs) {
      await doc.reference.update({'isNewMessage': false});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_p')
          .where('receiver', isEqualTo: accountData['email'])
          .where('isNewMessage', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasNewMessage = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage('assets/image/parc.jpg'),
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(
                child: ListTile(
                  contentPadding: EdgeInsets.all(20.0),
                  title: Text(accountData['name'] ?? 'No Name',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${context.localizations.email}: ${accountData['email'] ?? 'No Email'}'),
                          Text('${context.localizations.location}: ${accountData['city'] ?? 'No City'}'),
                          Text('${context.localizations.phone}: ${accountData['phone'] ?? 'No Phone'}'),
                          Text(
                            '${context.localizations.last_login}: ${accountData['lastSeen'] != null ? (accountData['lastSeen'] as Timestamp).toDate().toString() : 'No Last Login'}',
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Column(
                          //   children: [
                          //     Padding(
                          //       padding:
                          //           const EdgeInsets.symmetric(horizontal: 8.0),
                          //       child: Container(
                          //         decoration: BoxDecoration(
                          //           color: Colors.white,
                          //           borderRadius: BorderRadius.circular(8),
                          //           boxShadow: [
                          //             BoxShadow(
                          //                 color: Colors.black.withOpacity(0.3),
                          //                 spreadRadius: 2,
                          //                 blurRadius: 5),
                          //           ],
                          //         ),
                          //         child: Padding(
                          //           padding: const EdgeInsets.all(0),
                          //           child: IconButton(
                          //             icon: Icon(Icons.map_outlined, color: Colors.yellow[700]),
                          //             onPressed: () {
                          //               Navigator.push(
                          //                 context,
                          //                 MaterialPageRoute(
                          //                   builder: (context) => MapScreen(),
                          //                 ),
                          //               );
                          //             },
                          //           ),
                          //
                          //
                          //         ),
                          //       ),
                          //     ),
                          //     const SizedBox(
                          //       height: 22,
                          //     ),
                          //   ],
                          // ),
                          SizedBox(width: 10,),
                          Column(
                            children: [
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(0),
                                    child:   Tooltip(message: 'المبادرات',
                                      child:  IconButton(
                                        icon: Icon(Icons.inventory_outlined,
                                            color: Colors.yellow[700]),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    FirebaseDisplayScreen(
                                                        userEmail:
                                                        accountData['email'] ??
                                                            'No Email')),
                                          );
                                        },
                                      ),
                                    ),

                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 22,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Consumer<ChatProvider>(
                        builder: (context, chatProvider, child) {

                          bool hasNewMessage = chatProvider.receivedMessagesCount > 0;

                          return   Tooltip(message: 'الدردشة',
                            child: IconButton(
                              icon: Icon(
                                hasNewMessage
                                    ? Icons.mark_unread_chat_alt_outlined
                                    : Icons.mark_chat_read_outlined,
                                color: hasNewMessage ? Colors.red : Colors.yellow[700],
                              ),
                              onPressed: () {

                                chatProvider.resetReceivedMessagesCount();


                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PrivetChatScreen(
                                      userEmail: accountData['email'] ?? 'No Email',
                                    ),
                                  ),
                                );
                              },
                            )
                          );
                        },
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountFilesScreen(
                            email: accountData['email'] ?? 'No Email'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// class AccountFilesScreen extends StatefulWidget {
//   final String email;
//
//   const AccountFilesScreen({required this.email, super.key});
//
//   @override
//   State<AccountFilesScreen> createState() => _AccountFilesScreenState();
// }
//
// class _AccountFilesScreenState extends State<AccountFilesScreen> {
//   bool isLoadingFiles = true;
//   List<Map<String, dynamic>> uploadedFiles = [];
//   List<Map<String, dynamic>> sentFiles = [];
//   String selectedCategory = '';
//   String searchQuery = '';
//   String searchFilter = 'name';
//   bool showSentFiles = false;
//   bool hasNewNotification = false;
//   List<String> notificationLog = [];
//
//   @override
//   void initState() {
//     initNotifications();
//     fetchNotifications();
//     loadNotificationState();
//   }
//
//
//   Future<void> initNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     final InitializationSettings initializationSettings =
//     InitializationSettings(android: initializationSettingsAndroid);
//
//     await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//   }
//
//   Future<void> loadNotificationState() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       hasNewNotification = prefs.getBool('hasNewNotification') ?? false;
//     });
//   }
//
//   Future<void> saveNotificationState(bool state) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('hasNewNotification', state);
//   }
//
//   Future<void> showNotification(String fileName) async {
//     User? user = FirebaseAuth.instance.currentUser;
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//     AndroidNotificationDetails(
//       'upload_channel',
//       'File Uploads',
//       channelDescription: 'Channel for file upload notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//     );
//
//     const NotificationDetails platformChannelSpecifics =
//     NotificationDetails(android: androidPlatformChannelSpecifics);
//
//     await flutterLocalNotificationsPlugin.show(
//       0,
//       'Upload Successful',
//       'File "$fileName" uploaded successfully.',
//       platformChannelSpecifics,
//     );
//
//     FirebaseFirestore.instance.collection('send').add({
//       'message': 'File "$fileName" uploaded successfully ${widget.email}.',
//       'email': widget.email,
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//
//     setState(() {
//       notificationLog.add('File "$fileName" uploaded successfully.');
//       hasNewNotification = true;
//     });
//
//     await saveNotificationState(true);
//   }
//
//   void fetchNotifications() {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     FirebaseFirestore.instance
//         .collection('send')
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .listen((snapshot) {
//       setState(() {
//         notificationLog =
//             snapshot.docs.map((doc) => doc['message'] as String).toList();
//       });
//     });
//   }
//
//   void openNotifications() {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => NotificationsScreen(
//           notifications: notificationLog
//               .map((notification) =>
//           {'title': 'Notification', 'description': notification})
//               .toList(), // تحويل النصوص إلى خرائط
//           onNotificationsViewed: () async {
//             setState(() {
//               hasNewNotification = false;
//             });
//             await saveNotificationState(false);
//           },
//         ),
//       ),
//     );
//   }
//
//   /// إرسال إشعار جديد
//   // Future<void> sendNotification(String message) async {
//   //   try {
//   //     // أضف الإشعار إلى مجموعة Firestore
//   //     await FirebaseFirestore.instance.collection('send').add({
//   //       'message': message,
//   //       'timestamp': Timestamp.now(),
//   //     });
//   //
//   //     // تحديث سجل الإشعارات وإظهار النقطة الحمراء
//   //     setState(() {
//   //       notificationLog.insert(0, message);
//   //       hasNewNotification = true; // إظهار النقطة الحمراء
//   //     });
//   //
//   //     saveNotificationState(true); // حفظ حالة الإشعار في SharedPreferences
//   //
//   //     // عرض رسالة نجاح
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text('Notification sent successfully!'),
//   //         backgroundColor: Colors.green,
//   //       ),
//   //     );
//   //   } catch (e) {
//   //     // عرض رسالة خطأ
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(
//   //         content: Text('Failed to send notification: $e'),
//   //         backgroundColor: Colors.red,
//   //       ),
//   //     );
//   //   }
//   // }
//
//   /// رفع ملف
//   Future<void> uploadFile(BuildContext context) async {
//     String? category = await showDialog<String>(
//       context: context,
//       builder: (context) {
//         return SimpleDialog(
//           title: const Text('Select Category'),
//           children: <Widget>[
//             SimpleDialogOption(
//               onPressed: () => Navigator.pop(context, 'WFP'),
//               child: const Text('WFP'),
//             ),
//             SimpleDialogOption(
//               onPressed: () => Navigator.pop(context, 'Vegetable'),
//               child: const Text('Vegetable'),
//             ),
//             SimpleDialogOption(
//               onPressed: () => Navigator.pop(context, 'Sanitary'),
//               child: const Text('Sanitary'),
//             ),
//             SimpleDialogOption(
//               onPressed: () => Navigator.pop(context, 'Waters'),
//               child: const Text('Waters'),
//             ),
//             SimpleDialogOption(
//               onPressed: () => Navigator.pop(context, 'Initiatives'),
//               child: const Text('Initiatives'),
//             ),
//             SimpleDialogOption(
//               onPressed: () => Navigator.pop(context, 'Food'),
//               child: const Text('Food'),
//             ),
//             SimpleDialogOption(
//               onPressed: () => Navigator.pop(context, 'Dry'),
//               child: const Text('Dry'),
//             ),
//             SimpleDialogOption(
//               onPressed: () => Navigator.pop(context, 'Other'),
//               child: const Text('Other'),
//             ),
//           ],
//         );
//       },
//     );
//     if (category == null) return;
//     setState(() {
//       selectedCategory = category;
//     });
//     FilePickerResult? result =
//     await FilePicker.platform.pickFiles(type: FileType.any);
//     if (result == null || result.files.isEmpty) return;
//
//     try {
//       User? user = FirebaseAuth.instance.currentUser;
//       if (user == null) throw Exception("User not logged in");
//       final fileBytes = result.files.first.bytes;
//       final fileName = result.files.first.name;
//
//       if (fileBytes != null) {
//
//         final storageRef =
//         FirebaseStorage.instance.ref().child('download/$fileName');
//         SettableMetadata metadata = SettableMetadata(customMetadata: {
//           'category': category,
//           'sand_email': user.email!,
//           'uploader_email':widget.email,
//         });
//         await storageRef.putData(fileBytes, metadata);
//
//         await fetchUploadedFiles();
//
//         // إرسال الإشعار بعد رفع الملف
//         // String notificationMessage =
//         //     '$fileName uploaded successfully.';
//         // await sendNotification(notificationMessage);
//         //
//         // // تحديث سجل الإشعارات المحلي
//         // setState(() {
//         //   notificationLog.insert(0, notificationMessage);
//         //   hasNewNotification = true;
//         // });
//         await showNotification(fileName);
//
//         showDialog(
//           context: context,
//           builder: (context) {
//             return AlertDialog(
//               title: const Text('Success'),
//               content: const Text('Uploaded successfully.'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: const Text('OK'),
//                 ),
//               ],
//             );
//           },
//         );
//       }
//     } catch (e) {
//       showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text('Error'),
//             content: Text('Error uploading file: $e'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('OK'),
//               ),
//             ],
//           );
//         },
//       );
//     }
//   }
//
//   Future<void> fetchFiles() async {
//     await fetchUploadedFiles();
//     await fetchSentFiles();
//   }
//
//   Future<void> fetchUploadedFiles() async {
//     try {
//       final ListResult result =
//           await FirebaseStorage.instance.ref().child('uploads').listAll();
//
//       List<Map<String, dynamic>> files = [];
//
//       for (var ref in result.items) {
//         final metadata = await ref.getMetadata();
//         if (metadata.customMetadata?['uploader_email'] == widget.email) {
//           files.add({
//             'name': ref.name,
//             'date': metadata.timeCreated,
//             'ref': ref,
//             'category': metadata.customMetadata?['category'] ?? 'Unknown',
//             'uploader_email':
//                 metadata.customMetadata?['uploader_email'] ?? 'Unknown',
//           });
//         }
//       }
//
//       files.sort((a, b) => b['date'].compareTo(a['date']));
//
//       setState(() {
//         uploadedFiles = files;
//         isLoadingFiles = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoadingFiles = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching uploaded files: $e')),
//       );
//     }
//   }
//
//   Future<void> fetchSentFiles() async {
//     try {
//       final ListResult result =
//           await FirebaseStorage.instance.ref().child('download').listAll();
//
//       List<Map<String, dynamic>> files = [];
//
//       for (var ref in result.items) {
//         final metadata = await ref.getMetadata();
//         if (metadata.customMetadata?['sand_email'] == widget.email) {
//           files.add({
//             'name': ref.name,
//             'date': metadata.timeCreated,
//             'ref': ref,
//             'category': metadata.customMetadata?['category'] ?? 'Unknown',
//             'uploader_email':
//                 metadata.customMetadata?['uploader_email'] ?? 'Unknown',
//           });
//         }
//       }
//
//       files.sort((a, b) => b['date'].compareTo(a['date']));
//
//       setState(() {
//         sentFiles = files;
//         isLoadingFiles = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoadingFiles = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching sent files: $e')),
//       );
//     }
//   }
//
//   Widget getFileIcon(String fileName) {
//     if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
//       return const Icon(Icons.table_chart, color: Colors.green);
//     } else if (fileName.endsWith('.pdf')) {
//       return const Icon(Icons.picture_as_pdf, color: Colors.red);
//     } else if (fileName.endsWith('.jpg') || fileName.endsWith('.png')) {
//       return const Icon(Icons.image, color: Colors.grey);
//     } else {
//       return const Icon(Icons.insert_drive_file, color: Colors.blueAccent);
//     }
//   }
//
//   List<Map<String, dynamic>> getFilteredFiles() {
//     List<Map<String, dynamic>> filesToFilter =
//         showSentFiles ? sentFiles : uploadedFiles;
//
//     if (searchQuery.isEmpty) {
//       return filesToFilter
//           .where((file) =>
//               file['category'] == selectedCategory || selectedCategory.isEmpty)
//           .toList();
//     }
//     return filesToFilter.where((file) {
//       return file[searchFilter]
//               .toString()
//               .toLowerCase()
//               .contains(searchQuery.toLowerCase()) &&
//           (file['category'] == selectedCategory || selectedCategory.isEmpty);
//     }).toList();
//   }
//
//   Future<void> downloadFile(Reference ref, BuildContext context) async {
//     try {
//       final String url = await ref.getDownloadURL();
//
//       if (await canLaunch(url)) {
//         await launch(url);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error opening file URL')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error downloading file: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.yellow[700],
//         title: Text(
//           showSentFiles
//               ? '${context.localizations.sent_files_for} ${widget.email}'
//               : '${context.localizations.files_for} ${widget.email}',
//           style:
//               const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                       color: Colors.black.withOpacity(0.3),
//                       spreadRadius: 2,
//                       blurRadius: 5),
//                 ],
//               ),
//               child: IconButton(
//                 icon: Icon(
//                   showSentFiles ? Icons.upload_file : Icons.send,
//                   color: Colors.yellow[700],
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => SendScreen(email: widget.email),
//                     ),
//                   );
//                   setState(() {
//                     showSentFiles = !showSentFiles;
//                     if (showSentFiles) {
//                       fetchSentFiles();
//                     } else {
//                       fetchUploadedFiles();
//                     }
//                   });
//                 },
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                       color: Colors.black.withOpacity(0.3),
//                       spreadRadius: 2,
//                       blurRadius: 5),
//                 ],
//               ),
//               child: IconButton(
//                 icon: Icon(
//                   Icons.arrow_forward_ios_outlined,
//                   color: Colors.yellow[700],
//                 ),
//                 onPressed: () {
//                   Navigator.pushReplacementNamed(context, '/admin');
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: Image.asset(
//               'assets/image/parc.jpg',
//               fit: BoxFit.cover,
//             ),
//           ),
//           Positioned.fill(
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//               child: Container(
//                 color: Colors.black.withOpacity(0),
//               ),
//             ),
//           ),
//           buildContent(),
//         ],
//       ),
//     );
//   }
//
//   Widget buildContent() {
//     return Row(
//       children: [
//         Container(
//           width: 100,
//           color: Colors.grey[200],
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     shape: const CircleBorder(),
//                     backgroundColor: Colors.white,
//                     padding: const EdgeInsets.all(12),
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       selectedCategory = '';
//                       searchQuery = '';
//                     });
//                   },
//                   child: Icon(
//                     Icons.folder,
//                     size: 30,
//                     color: Colors.yellow[700],
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 const Text(
//                   'All',
//                   style: TextStyle(fontSize: 12),
//                   textAlign: TextAlign.center,
//                 ),
//                 ...getFilteredFiles()
//                     .map((file) => file['category'])
//                     .toSet()
//                     .map((category) {
//                   return Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Column(
//                       children: [
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             shape: const CircleBorder(),
//                             backgroundColor: Colors.white,
//                             padding: const EdgeInsets.all(12),
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               selectedCategory = category;
//                               searchQuery = '';
//                             });
//                           },
//                           child: Icon(
//                             Icons.folder,
//                             size: 30,
//                             color: Colors.yellow[700],
//                           ),
//                         ),
//                         const SizedBox(height: 5),
//                         Text(
//                           category,
//                           style: const TextStyle(fontSize: 12),
//                           textAlign: TextAlign.center,
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               ],
//             ),
//           ),
//         ),
//         Expanded(
//           child: Column(
//             children: [
//               const SizedBox(height: 10),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 10),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8.0),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.5),
//                               spreadRadius: 2,
//                               blurRadius: 5,
//                               offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: TextField(
//                           decoration: InputDecoration(
//                             labelText: 'Search',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8.0),
//                               borderSide: BorderSide.none,
//                             ),
//                             fillColor: Colors.white,
//                             filled: true,
//                           ),
//                           onChanged: (value) {
//                             setState(() {
//                               searchQuery = value;
//                             });
//                           },
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     DropdownButton<String>(
//                       value: searchFilter,
//                       items: const [
//                         DropdownMenuItem(
//                           value: 'name',
//                           child: Text(
//                             'Name',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         DropdownMenuItem(
//                           value: 'uploader_email',
//                           child: Text(
//                             'Email',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         DropdownMenuItem(
//                           value: 'category',
//                           child: Text(
//                             'Category',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         DropdownMenuItem(
//                           value: 'date',
//                           child: Text(
//                             'Date',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                       onChanged: (value) {
//                         setState(() {
//                           searchFilter = value!;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Expanded(
//                 child: isLoadingFiles
//                     ? const Center(child: CircularProgressIndicator())
//                     : ListView(
//                         children: getFilteredFiles().map((file) {
//                           return Container(
//                             margin: const EdgeInsets.symmetric(
//                                 vertical: 5.0, horizontal: 10.0),
//                             padding: const EdgeInsets.all(10.0),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(10.0),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.grey.withOpacity(0.5),
//                                   spreadRadius: 2,
//                                   blurRadius: 5,
//                                   offset: const Offset(0, 3),
//                                 ),
//                               ],
//                             ),
//                             child: ListTile(
//                               leading: getFileIcon(file['name']),
//                               title: Text(
//                                 file['name'],
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black87),
//                               ),
//                               subtitle: Text(
//                                 'Date: ${file['date']}\nCategory: ${file['category']}\nUploaded by: ${file['uploader_email']}',
//                                 style: const TextStyle(color: Colors.black54),
//                               ),
//                               trailing: Column(
//                                 children: [
//                                   IconButton(
//                                     icon: const Icon(Icons.download,
//                                         color: Colors.green),
//                                     onPressed: () =>
//                                         downloadFile(file['ref'], context),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                       ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.white,
//                     backgroundColor: Colors.blueAccent,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                   ),
//                   onPressed: () => uploadFile(context),
//                   icon: const Icon(Icons.upload_file),
//                   label: const Text('Upload File'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }



class AccountFilesScreen extends StatefulWidget {
  final String email;

  const AccountFilesScreen({required this.email, super.key});

  @override
  State<AccountFilesScreen> createState() => _AccountFilesScreenState();
}

class _AccountFilesScreenState extends State<AccountFilesScreen> {
  bool isLoadingFiles = true;
  List<Map<String, dynamic>> uploadedFiles = [];
  List<Map<String, dynamic>> sentFiles = [];
  String selectedCategory = '';
  String searchQuery = '';
  String searchFilter = 'name';
  bool showSentFiles = false;
  bool hasNewNotification = false;
  List<String> notificationLog = [];
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initNotifications();
    fetchNotifications();
    loadNotificationState();
    fetchFiles();
  }

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hasNewNotification = prefs.getBool('hasNewNotification') ?? false;
    });
  }

  Future<void> saveNotificationState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasNewNotification', state);
  }

  Future<void> showNotification(String fileName) async {
    User? user = FirebaseAuth.instance.currentUser;
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'upload_channel',
      'File Uploads',
      channelDescription: 'Channel for file upload notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Upload Successful',
      'File "$fileName" uploaded successfully.',
      platformChannelSpecifics,
    );

    FirebaseFirestore.instance.collection('send').add({
      'message': 'File "$fileName" uploaded successfully ${widget.email}.',
      'email': widget.email,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      notificationLog.add('File "$fileName" uploaded successfully.');
      hasNewNotification = true;
    });

    await saveNotificationState(true);
  }

  void fetchNotifications() {
    FirebaseFirestore.instance
        .collection('send')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        notificationLog =
            snapshot.docs.map((doc) => doc['message'] as String).toList();
      });
    });
  }

  Future<void> fetchFiles() async {
    await fetchUploadedFiles();
    await fetchSentFiles();
  }
  //
  // Future<void> fetchUploadedFiles() async {
  //   try {
  //     final ListResult result =
  //     await FirebaseStorage.instance.ref().child('uploads').listAll();
  //
  //     List<Map<String, dynamic>> files = [];
  //
  //     for (var ref in result.items) {
  //       final metadata = await ref.getMetadata();
  //       if (metadata.customMetadata?['uploader_email'] == widget.email) {
  //         files.add({
  //           'name': ref.name,
  //           'date': metadata.timeCreated,
  //           'ref': ref,
  //           'category': metadata.customMetadata?['category'] ?? 'Unknown',
  //           'uploader_email':
  //           metadata.customMetadata?['uploader_email'] ?? 'Unknown',
  //         });
  //       }
  //     }
  //
  //     files.sort((a, b) => b['date'].compareTo(a['date']));
  //
  //     setState(() {
  //       uploadedFiles = files;
  //       isLoadingFiles = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       isLoadingFiles = false;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error fetching uploaded files: $e')),
  //     );
  //   }
  // }
  //
  // Future<void> fetchSentFiles() async {
  //   try {
  //     final ListResult result =
  //     await FirebaseStorage.instance.ref().child('download').listAll();
  //
  //     List<Map<String, dynamic>> files = [];
  //
  //     for (var ref in result.items) {
  //       final metadata = await ref.getMetadata();
  //       if (metadata.customMetadata?['sand_email'] == widget.email) {
  //         files.add({
  //           'name': ref.name,
  //           'date': metadata.timeCreated,
  //           'ref': ref,
  //           'category': metadata.customMetadata?['category'] ?? 'Unknown',
  //           'uploader_email':
  //           metadata.customMetadata?['uploader_email'] ?? 'Unknown',
  //         });
  //       }
  //     }
  //
  //     files.sort((a, b) => b['date'].compareTo(a['date']));
  //
  //     setState(() {
  //       sentFiles = files;
  //       isLoadingFiles = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       isLoadingFiles = false;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error fetching sent files: $e')),
  //     );
  //   }
  // }
  Future<void> fetchUploadedFiles() async {
    try {
      setState(() {
        isLoadingFiles = true;
      });

      final ListResult result =
      await FirebaseStorage.instance.ref().child('uploads').listAll();

      List<Map<String, dynamic>> files = [];

      for (var ref in result.items) {
        final metadata = await ref.getMetadata();
        if (metadata.customMetadata?['uploader_email'] == widget.email) {
          files.add({
            'name': ref.name,
            'date': metadata.timeCreated,
            'ref': ref,
            'category': metadata.customMetadata?['category'] ?? 'Unknown',
            'uploader_email': metadata.customMetadata?['uploader_email'] ?? 'Unknown',
          });
        }
      }

      files.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        uploadedFiles = files;
        isLoadingFiles = false;
      });
    } catch (e) {
      setState(() {
        isLoadingFiles = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching uploaded files: $e')),
      );
    }
  }

  Future<void> fetchSentFiles() async {
    try {
      setState(() {
        isLoadingFiles = true;
      });

      final ListResult result =
      await FirebaseStorage.instance.ref().child('download').listAll();

      List<Map<String, dynamic>> files = [];

      for (var ref in result.items) {
        final metadata = await ref.getMetadata();
        if (metadata.customMetadata?['sand_email'] == widget.email) {
          files.add({
            'name': ref.name,
            'date': metadata.timeCreated,
            'ref': ref,
            'category': metadata.customMetadata?['category'] ?? 'Unknown',
            'uploader_email': metadata.customMetadata?['uploader_email'] ?? 'Unknown',
          });
        }
      }

      files.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        sentFiles = files;
        isLoadingFiles = false;
      });
    } catch (e) {
      setState(() {
        isLoadingFiles = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching sent files: $e')),
      );
    }
  }

  List<Map<String, dynamic>> getFilteredFiles() {
    List<Map<String, dynamic>> filesToFilter =
    showSentFiles ? sentFiles : uploadedFiles;

    if (searchQuery.isEmpty) {
      return filesToFilter
          .where((file) =>
      file['category'] == selectedCategory || selectedCategory.isEmpty)
          .toList();
    }
    return filesToFilter.where((file) {
      return file[searchFilter]
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase()) &&
          (file['category'] == selectedCategory || selectedCategory.isEmpty);
    }).toList();
  }

  Future<void> downloadFile(Reference ref, BuildContext context) async {
    try {
      final String url = await ref.getDownloadURL();

      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening file URL')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }

  Widget getFileIcon(String fileName) {
    if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
      return const Icon(Icons.table_chart, color: Colors.green);
    } else if (fileName.endsWith('.pdf')) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.png')) {
      return const Icon(Icons.image, color: Colors.grey);
    } else {
      return const Icon(Icons.wordpress_outlined, color: Colors.blueAccent);
    }
  }
  Future<void> uploadFile(BuildContext context) async {
    String? category = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title:  Text(context.localizations.select_category),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'WFP'),
              child:  const Text('WFP'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'خضار'),
              child:  Text(context.localizations.vegetable),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'طرود صحية'),
              child:  Text(context.localizations.sanitary),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'مياه'),
              child:  Text(context.localizations.waters),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'مبادرات'),
              child:  Text(context.localizations.initiatives),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'غذاء'),
              child:  Text(context.localizations.food),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'طرود جافة'),
              child:  Text(context.localizations.dry),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'اخرى'),
              child:  Text(context.localizations.other),
            ),
          ],
        );
      },
    );
    if (category == null) return;
    setState(() {
      selectedCategory = category;
    });
    FilePickerResult? result =
    await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      final fileBytes = result.files.first.bytes;
      final fileName = result.files.first.name;

      if (fileBytes != null) {

        final storageRef =
        FirebaseStorage.instance.ref().child('download/$fileName');
        SettableMetadata metadata = SettableMetadata(customMetadata: {
          'category': category,
          'sand_email': user.email!,
          'uploader_email':widget.email,
        });
        await storageRef.putData(fileBytes, metadata);

        await fetchUploadedFiles();

        // إرسال الإشعار بعد رفع الملف
        // String notificationMessage =
        //     '$fileName uploaded successfully.';
        // await sendNotification(notificationMessage);
        //
        // // تحديث سجل الإشعارات المحلي
        // setState(() {
        //   notificationLog.insert(0, notificationMessage);
        //   hasNewNotification = true;
        // });
        await showNotification(fileName);

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Uploaded successfully.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Error uploading file: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }


  // Widget buildContent() {
  //   return Row(
  //     children: [
  //       Container(
  //         width: 100,
  //         color: Colors.grey[200],
  //         child: SingleChildScrollView(
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.start,
  //             children: [
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(
  //                   shape: const CircleBorder(),
  //                   backgroundColor: Colors.white,
  //                   padding: const EdgeInsets.all(12),
  //                 ),
  //                 onPressed: () {
  //                   setState(() {
  //                     selectedCategory = '';
  //                     searchQuery = '';
  //                   });
  //                 },
  //                 child: Icon(
  //                   Icons.folder,
  //                   size: 30,
  //                   color: Colors.yellow[700],
  //                 ),
  //               ),
  //               const SizedBox(height: 5),
  //               const Text(
  //                 'All',
  //                 style: TextStyle(fontSize: 12),
  //                 textAlign: TextAlign.center,
  //               ),
  //               ...getFilteredFiles()
  //                   .map((file) => file['category'])
  //                   .toSet()
  //                   .map((category) {
  //                 return Padding(
  //                   padding: const EdgeInsets.all(8.0),
  //                   child: Column(
  //                     children: [
  //                       ElevatedButton(
  //                         style: ElevatedButton.styleFrom(
  //                           shape: const CircleBorder(),
  //                           backgroundColor: Colors.white,
  //                           padding: const EdgeInsets.all(12),
  //                         ),
  //                         onPressed: () {
  //                           setState(() {
  //                             selectedCategory = category;
  //                             searchQuery = '';
  //                           });
  //                         },
  //                         child: Icon(
  //                           Icons.folder,
  //                           size: 30,
  //                           color: Colors.yellow[700],
  //                         ),
  //                       ),
  //                       const SizedBox(height: 5),
  //                       Text(
  //                         category,
  //                         style: const TextStyle(fontSize: 12),
  //                         textAlign: TextAlign.center,
  //                       ),
  //                     ],
  //                   ),
  //                 );
  //               }).toList(),
  //             ],
  //           ),
  //         ),
  //       ),
  //       Expanded(
  //         child: Column(
  //           children: [
  //             const SizedBox(height: 10),
  //             Padding(
  //               padding: const EdgeInsets.symmetric(horizontal: 10),
  //               child: Row(
  //                 children: [
  //                   Expanded(
  //                     child: Container(
  //                       decoration: BoxDecoration(
  //                         color: Colors.white,
  //                         borderRadius: BorderRadius.circular(8.0),
  //                         boxShadow: [
  //                           BoxShadow(
  //                             color: Colors.grey.withOpacity(0.5),
  //                             spreadRadius: 2,
  //                             blurRadius: 5,
  //                             offset: const Offset(0, 3),
  //                           ),
  //                         ],
  //                       ),
  //                       child: TextField(
  //                         decoration: InputDecoration(
  //                           labelText: 'Search',
  //                           border: OutlineInputBorder(
  //                             borderRadius: BorderRadius.circular(8.0),
  //                             borderSide: BorderSide.none,
  //                           ),
  //                           fillColor: Colors.white,
  //                           filled: true,
  //                         ),
  //                         onChanged: (value) {
  //                           setState(() {
  //                             searchQuery = value;
  //                           });
  //                         },
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 10),
  //                   DropdownButton<String>(
  //                     value: searchFilter,
  //                     items: const [
  //                       DropdownMenuItem(
  //                         value: 'name',
  //                         child: Text(
  //                           'Name',
  //                           style: TextStyle(
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                       ),
  //                       DropdownMenuItem(
  //                         value: 'uploader_email',
  //                         child: Text(
  //                           'Email',
  //                           style: TextStyle(
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                       ),
  //                       DropdownMenuItem(
  //                         value: 'category',
  //                         child: Text(
  //                           'Category',
  //                           style: TextStyle(
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                       ),
  //                       DropdownMenuItem(
  //                         value: 'date',
  //                         child: Text(
  //                           'Date',
  //                           style: TextStyle(
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                     onChanged: (value) {
  //                       setState(() {
  //                         searchFilter = value!;
  //                       });
  //                     },
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 10),
  //             Expanded(
  //               child: isLoadingFiles
  //                   ? const Center(child: CircularProgressIndicator())
  //                   : ListView(
  //                 children: getFilteredFiles().map((file) {
  //                   return Container(
  //                     margin: const EdgeInsets.symmetric(
  //                         vertical: 5.0, horizontal: 10.0),
  //                     padding: const EdgeInsets.all(10.0),
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(10.0),
  //                       boxShadow: [
  //                         BoxShadow(
  //                           color: Colors.grey.withOpacity(0.5),
  //                           spreadRadius: 2,
  //                           blurRadius: 5,
  //                           offset: const Offset(0, 3),
  //                         ),
  //                       ],
  //                     ),
  //                     child: ListTile(
  //                       leading: getFileIcon(file['name']),
  //                       title: Text(
  //                         file['name'],
  //                         style: const TextStyle(
  //                             fontWeight: FontWeight.bold,
  //                             color: Colors.black87),
  //                       ),
  //                       subtitle: Text(
  //                         'Date: ${file['date']}\nCategory: ${file['category']}\nUploaded by: ${file['uploader_email']}',
  //                         style: const TextStyle(color: Colors.black54),
  //                       ),
  //                       trailing: Column(
  //                         children: [
  //                           IconButton(
  //                             icon: const Icon(Icons.download,
  //                                 color: Colors.green),
  //                             onPressed: () =>
  //                                 downloadFile(file['ref'], context),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   );
  //                 }).toList(),
  //               ),
  //             ),
  //             Padding(
  //               padding: const EdgeInsets.all(10.0),
  //               child: ElevatedButton.icon(
  //                 style: ElevatedButton.styleFrom(
  //                   foregroundColor: Colors.white,
  //                   backgroundColor: Colors.blueAccent,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(10.0),
  //                   ),
  //                 ),
  //                 onPressed: () => uploadFile(context),
  //                 icon: const Icon(Icons.upload_file),
  //                 label: const Text('Upload File'),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget buildContent() {
    List<Map<String, dynamic>> files = getFilteredFiles();

    return Row(
      children: [
        // Sidebar
        Container(
          width: 100,
          color: Colors.grey[200],
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedCategory = '';
                      searchQuery = '';
                    });
                  },
                  child: Icon(
                    Icons.folder,
                    size: 30,
                    color: Colors.yellow[700],
                  ),
                ),
                const SizedBox(height: 5),
                 const Text(
                  'All',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                ...files
                    .map((file) => file['category'])
                    .toSet()
                    .map((category) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedCategory = category;
                              searchQuery = '';
                            });
                          },
                          child: Icon(
                            Icons.folder,
                            size: 30,
                            color: Colors.yellow[700],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          category,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        // Main Content
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: context.localizations.search,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: searchFilter,
                      items:  [
                        DropdownMenuItem(
                          value: 'name',
                          child: Text(
                            context.localizations.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'uploader_email',
                          child: Text(
                            context.localizations.email,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category',
                          child: Text(
                            context.localizations.category,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'date',
                          child: Text(
                            context.localizations.date,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          searchFilter = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: isLoadingFiles
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final previousFile =
                    index > 0 ? files[index - 1] : null;

                    final currentFileDate = file['date'] is DateTime
                        ? file['date']
                        : DateTime.parse(file['date']);
                    final previousFileDate = previousFile != null &&
                        previousFile['date'] is DateTime
                        ? previousFile['date']
                        : previousFile != null
                        ? DateTime.parse(previousFile['date'])
                        : null;

                    // Check if the month or year has changed
                    final isNewMonth = previousFile == null ||
                        currentFileDate.month != previousFileDate?.month ||
                        currentFileDate.year != previousFileDate?.year;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isNewMonth)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[400],
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(
                                    '${currentFileDate.year} - ${currentFileDate.month}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[400],
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 10.0),
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: getFileIcon(file['name']),
                            title: Text(
                              file['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            subtitle: Text(
                              'Date: ${file['date']}\nCategory: ${file['category']}\nUploaded by: ${file['uploader_email']}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing:   Tooltip(message: 'تنزيل',
                              child: IconButton(
                                icon: const Icon(Icons.download,
                                    color: Colors.green),
                                onPressed: () =>
                                    downloadFile(file['ref'], context),
                              ),
                            ),

                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () => uploadFile(context),
                  icon: const   Tooltip(message: 'رفع ملف',
                    child: Icon(Icons.upload_file),
                  ),

                  label: const Text('Upload File'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text(
          showSentFiles
              ? '${context.localizations.sent_files_for} ${widget.email}'
              : '${context.localizations.files_for} ${widget.email}',
          style:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
                icon:   Tooltip(message: 'المرسل',
                  child:  Icon(
                    showSentFiles ? Icons.upload_file : Icons.send,
                    color: Colors.yellow[700],
                  ),
                ),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SendScreen(email: widget.email),
                    ),
                  );
                  setState(() {
                    showSentFiles = !showSentFiles;
                    if (showSentFiles) {
                      fetchSentFiles();
                    } else {
                      fetchUploadedFiles();
                    }
                  });
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
                icon:  Tooltip(message: 'الرجوع',
                  child:Icon(
                    Icons.arrow_forward_ios_outlined,
                    color: Colors.yellow[700],
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/admin');
                },
              ),
            ),
          ),
        ],
      ),
      body:Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/image/parc.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0),
              ),
            ),
          ),
          buildContent(),
        ],
      ),
    );
  }
}


class NootificationsScreen extends StatelessWidget {
  final List<Map<String, String>> notifications;
  final VoidCallback onNotificationsViewed;

  const NootificationsScreen({
    super.key,
    required this.notifications,
    required this.onNotificationsViewed,
  });

  @override
  Widget build(BuildContext context) {
    // عند فتح الصفحة، سيتم تنفيذ الوظيفة للتحديث
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNotificationsViewed();
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'No Notifications!',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification['description'] ?? 'No Description',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
