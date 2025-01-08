import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled4/components/context-extenssion.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';

class SendScreen extends StatefulWidget {
  final String email;

  const SendScreen({super.key, required this.email});

  @override
  _SendScreenState createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  bool isLoading = true;
  bool isLoadingFiles = false;
  List<Map<String, dynamic>> downloadedFiles = [];
  Map<String, List<Map<String, dynamic>>> categorizedFiles = {};
  String selectedCategory = '';
  String searchQuery = '';
  String searchFilter = 'name';
  bool hasNewNotification = false;
  List<String> notificationLog = [];
  String lastViewedTimestamp = DateTime.now().toIso8601String();

  @override
  void initState() {
    super.initState();
    fetchDownloadedFiles();
    initNotifications();
    fetchNotifications();
    loadNotificationState();
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
      lastViewedTimestamp =
          prefs.getString('lastViewedTimestamp') ?? DateTime.now().toIso8601String();
    });
  }
  Future<void> saveNotificationState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasNewNotification', state);
    await prefs.setString('lastViewedTimestamp', DateTime.now().toIso8601String());
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
        .where('email', isEqualTo: widget.email) // تصفية الإشعارات حسب البريد الإلكتروني
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final List<String> newNotificationLog =
      snapshot.docs.map((doc) => doc['message'] as String).toList();

      final bool isNewNotification = snapshot.docs.any((doc) {
        final timestamp = (doc['timestamp'] as Timestamp).toDate();
        return timestamp.isAfter(DateTime.parse(lastViewedTimestamp));
      });

      setState(() {
        notificationLog = newNotificationLog;
        hasNewNotification = isNewNotification;
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
              .toList(),
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
  Future<void> fetchDownloadedFiles() async {
    try {
      final ListResult result =
          await FirebaseStorage.instance.ref().child('download').listAll();
      List<Map<String, dynamic>> files = [];

      for (var ref in result.items) {
        final metadata = await ref.getMetadata();
        if (metadata.customMetadata?['uploader_email'] == widget.email) {
          files.add({
            'name': ref.name,
            'date': metadata.timeCreated,
            'ref': ref,
            'category': metadata.customMetadata?['category'] ?? 'category',
            'uploader_email':
                metadata.customMetadata?['uploader_email'] ?? 'email',
            'sand_email': metadata.customMetadata?['sand_email'] ?? 'sand',
          });
        }
      }

      files.sort((a, b) => b['date'].compareTo(a['date']));
      categorizedFiles = {for (var file in files) file['category']: []};
      for (var file in files) {
        categorizedFiles[file['category']]!.add(file);
      }

      setState(() {
        downloadedFiles = files;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching files: $e')),
      );
    }
  }
  List<Map<String, dynamic>> getFilteredFiles() {
    return downloadedFiles.where((file) {
      final matchesCategory =
          file['category'] == selectedCategory || selectedCategory.isEmpty;
      final matchesSearch = file[searchFilter]
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }
  Future<void> downloadFile(Reference ref, BuildContext context) async {
    try {
      final url = await ref.getDownloadURL();

      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the file.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }
  void shareFile(String fileName, String url) {
    Share.share('Check out this file: $fileName\nDownload link: $url');
  }
  Widget getFileIcon(String fileName) {
    if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
      return const Icon(Icons.table_chart, color: Colors.green);
    } else if (fileName.endsWith('.pdf')) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.png')) {
      return const Icon(Icons.image, color: Colors.grey);
    } else {
      return const Icon(Icons.insert_drive_file, color: Colors.blueAccent);
    }
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
      appBar: AppBar(
        title:  Text(
          context.localizations.in_box,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.yellow[700],
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Stack(
              children: [
                IconButton(
                  onPressed: openNotifications,
                  icon: const Icon(Icons.notifications),
                  color: Colors.white,
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
              child:  Tooltip(message: 'الرجوع',
                child: IconButton(
                  onPressed: () async {
                    bool isAdmin = await checkIfUserIsAdmin();
                    if (isAdmin) {
                      Navigator.pushReplacementNamed(context, '/admin');
                    } else {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  icon: const Icon(Icons.arrow_forward_ios_outlined),
                ),
              ),

            ),
          ),
        ],
      ),
      body: Stack(
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

  Widget buildContent() {
    return Row(
      children: [
        // Sidebar with scrollable content
        Container(
          width: 120,
          color: Colors.grey[200],
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                ...categorizedFiles.keys.map((category) {
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
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // Main Content Area
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'date',
                          child: Text(
                            context.localizations.date,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category',
                          child: Text(
                            context.localizations.category,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'uploader_email',
                          child: Text(
                            context.localizations.uploader_email,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
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
              // Display the number of files
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${context.localizations.total_files}: ${getFilteredFiles().length}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              const SizedBox(height: 10),
              isLoadingFiles
                  ? const Center(child: CircularProgressIndicator())
                  : Expanded(
                child: ListView(
                  children: getFilteredFiles().map((file) {
                    return Container(
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
                          '${file['date']?.toLocal() ?? 'Unknown'}\nCategory: ${file['category']}\nEmail: ${file['uploader_email']}\nSand: ${file['sand_email']}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(message: 'تنزيل',
                              child:  IconButton(
                                icon: const Icon(Icons.download,
                                    color: Colors.blue),
                                onPressed: () =>
                                    downloadFile(file['ref'], context),
                              ),
                            ),

                            Tooltip(message: 'مشاركة',
                              child:  IconButton(
                                icon: const Icon(Icons.share,
                                    color: Colors.green),
                                onPressed: () {
                                  final url = file['ref'].getDownloadURL();
                                  url.then((value) {
                                    shareFile(file['name'], value);
                                  });
                                },
                              ),
                            ),

                          ],
                        ),
                        onTap: () => downloadFile(file['ref'], context),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
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
