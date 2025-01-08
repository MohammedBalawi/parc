import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:untitled4/components/context-extenssion.dart';

class UploadFileScreen extends StatefulWidget {
  const UploadFileScreen({super.key});

  @override
  _UploadFileScreenState createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool isUploading = false;
  bool isDeleting = false;
  bool isLoadingFiles = true;
  List<Map<String, dynamic>> uploadedFiles = [];
  List<String> notificationLog = [];
  bool hasNewNotification = false;
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    fetchUploadedFiles();
    fetchNotifications();
    initNotifications();
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
      'Upload Successful to admin by ${user?.email} ',
      'File "$fileName" uploaded successfully to admin.'
          '${user?.email}',
      platformChannelSpecifics,
    );

    FirebaseFirestore.instance.collection('notifications').add({
      'message': 'File : $fileName" uploaded successfully by : ${user?.email}.',
      'email': user?.email,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      notificationLog.add('File "$fileName" uploaded successfully by ${user?.email}');
      hasNewNotification = true;
    });

    await saveNotificationState(true);
  }
  Future<void> fetchNotifications() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      notificationLog = snapshot.docs
          .map((doc) => doc['message'] as String)
          .toList();
    });
  }
  // Future<void> uploadFile() async {
  //   String? category = await showDialog<String>(
  //     context: context,
  //     builder: (context) {
  //       return SimpleDialog(
  //         title:  Text(context.localizations.select_category),
  //         children: <Widget>[
  //           SimpleDialogOption(
  //             onPressed: () => Navigator.pop(context, 'WFP'),
  //             child: const Text('WFP'),
  //           ),
  //           SimpleDialogOption(
  //             onPressed: () => Navigator.pop(context, 'خضار'),
  //             child:  Text(context.localizations.vegetable),
  //           ),
  //           SimpleDialogOption(
  //             onPressed: () => Navigator.pop(context, 'طرود صحية'),
  //             child:  Text(context.localizations.sanitary),
  //           ),
  //           SimpleDialogOption(
  //             onPressed: () => Navigator.pop(context, 'مياه'),
  //             child:  Text(context.localizations.waters),
  //           ),
  //           SimpleDialogOption(
  //             onPressed: () => Navigator.pop(context, 'مبادرات'),
  //             child:  Text(context.localizations.initiatives),
  //           ),
  //           SimpleDialogOption(
  //             onPressed: () => Navigator.pop(context, 'غذاء'),
  //             child:  Text(context.localizations.food),
  //           ),
  //           SimpleDialogOption(
  //             onPressed: () => Navigator.pop(context, 'طرود جاف'),
  //             child:  Text(context.localizations.dry),
  //           ),
  //           SimpleDialogOption(
  //             onPressed: () => Navigator.pop(context, 'اخرى'),
  //             child:  Text(context.localizations.other),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  //
  //   if (category == null) return;
  //   setState(() {
  //     selectedCategory = category;
  //   });
  //
  //   FilePickerResult? result = await FilePicker.platform.pickFiles();
  //   if (result == null) return;
  //
  //   setState(() {
  //     isUploading = true;
  //   });
  //
  //   try {
  //     User? user = FirebaseAuth.instance.currentUser;
  //     if (user == null) throw Exception("User not logged in");
  //
  //     Uint8List fileBytes = result.files.single.bytes as Uint8List;
  //     String fileName = result.files.single.name;
  //
  //     final storageRef =
  //     FirebaseStorage.instance.ref().child('uploads/$fileName');
  //
  //     SettableMetadata metadata = SettableMetadata(customMetadata: {
  //       'category': category,
  //       'uploader_email': user.email!,
  //     });
  //
  //     await storageRef.putData(fileBytes, metadata);
  //
  //     await fetchUploadedFiles();
  //
  //     await showNotification(fileName);
  //
  //     showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title:  Text(context.localizations.success),
  //           content:  Text(context.localizations.uploaded_successfully),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(),
  //               child:  Text(context.localizations.ok),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title:  Text(context.localizations.error),
  //           content: Text('${context.localizations.error_uploading_file}: $e'),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(),
  //               child:  Text(context.localizations.ok),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   } finally {
  //     setState(() {
  //       isUploading = false;
  //     });
  //   }
  // }
  //
  // Future<void> fetchUploadedFiles() async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;
  //
  //   final ListResult result =
  //   await FirebaseStorage.instance.ref().child('uploads').listAll();
  //
  //   List<Map<String, dynamic>> files = [];
  //
  //   for (var ref in result.items) {
  //     final metadata = await ref.getMetadata();
  //     if (metadata.customMetadata?['uploader_email'] == user.email) {
  //       files.add({
  //         'name': ref.name,
  //         'date': metadata.timeCreated,
  //         'ref': ref,
  //         'category': metadata.customMetadata?['category'] ?? 'Unknown',
  //         'rowCount': metadata.customMetadata?['rowCount'] ?? 'Unknown',
  //       });
  //     }
  //   }
  //
  //   files.sort((a, b) => b['date'].compareTo(a['date']));
  //
  //   setState(() {
  //     uploadedFiles = files;
  //     isLoadingFiles = false;
  //   });
  // }
  Future<void> uploadFile() async {
    String? category = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(context.localizations.select_category),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'WFP'),
              child: const Text('WFP'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'خضار'),
              child: Text(context.localizations.vegetable),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'طرود صحية'),
              child: Text(context.localizations.sanitary),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'مياه'),
              child: Text(context.localizations.waters),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'مبادرات'),
              child: Text(context.localizations.initiatives),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'غذاء'),
              child: Text(context.localizations.food),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'طرود جاف'),
              child: Text(context.localizations.dry),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'اخرى'),
              child: Text(context.localizations.other),
            ),
          ],
        );
      },
    );

    if (category == null) return;
    setState(() {
      selectedCategory = category;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result == null) return;

    setState(() {
      isUploading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      String fileName = result.files.single.name;
      Reference storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName');

      SettableMetadata metadata = SettableMetadata(customMetadata: {
        'category': category,
        'uploader_email': user.email!,
      });

      if (kIsWeb) {

        Uint8List fileBytes = result.files.single.bytes!;
        await storageRef.putData(fileBytes, metadata);
      } else {

        File file = File(result.files.single.path!);
        await storageRef.putFile(file, metadata);
      }

      await fetchUploadedFiles();
      await showNotification(fileName);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(context.localizations.success),
            content: Text(context.localizations.uploaded_successfully),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.localizations.ok),
              ),
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(context.localizations.error),
            content: Text('${context.localizations.error_uploading_file}: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.localizations.ok),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }
  Future<void> deleteFile(Reference ref) async {
    setState(() {
      isDeleting = true;
    });

    try {
      await ref.delete();
      await fetchUploadedFiles();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title:  Text(context.localizations.deleted),
            content:  Text(context.localizations.file_deleted_successfully),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child:  Text(context.localizations.ok),
              ),
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title:  Text(context.localizations.error),
            content: Text('${context.localizations.error_uploading_file}: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child:  Text(context.localizations.ok),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        isDeleting = false;
      });
    }
  }
  Future<void> fetchUploadedFiles() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ListResult result =
    await FirebaseStorage.instance.ref().child('uploads').listAll();

    List<Map<String, dynamic>> files = [];

    for (var ref in result.items) {
      final metadata = await ref.getMetadata();
      if (metadata.customMetadata?['uploader_email'] == user.email) {
        files.add({
          'name': ref.name,
          'date': metadata.timeCreated,
          'ref': ref,
          'category': metadata.customMetadata?['category'] ?? 'Unknown',
          'rowCount': metadata.customMetadata?['rowCount'] ?? 'Unknown',
        });
      }
    }

    files.sort((a, b) => b['date'].compareTo(a['date']));

    setState(() {
      uploadedFiles = files;
      isLoadingFiles = false;
    });
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
  void openNotifications() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => NotificationsScreen(
        notifications: notificationLog,
        onNotificationsViewed: () async {
          setState(() {
            hasNewNotification = false;
          });
          await saveNotificationState(false);
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title:  Text(
          context.localizations.upload_file,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 8.0),
          //   child: Stack(
          //     children: [
          //       IconButton(
          //         onPressed: openNotifications,
          //         icon: const Icon(Icons.notifications),
          //         color: hasNewNotification ? Colors.red : Colors.white,
          //       ),
          //       if (hasNewNotification)
          //         const Positioned(
          //           right: 11,
          //           top: 11,
          //           child: Icon(
          //             Icons.brightness_1,
          //             size: 8.0,
          //             color: Colors.redAccent,
          //           ),
          //         ),
          //     ],
          //   ),
          // ),
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
              child:
              Tooltip(message: 'الرجوع',
                child: IconButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  icon: const Icon(Icons.arrow_forward_ios_outlined),
                ),
              ),
            ),
          ),
        ],
      ),
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
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                isUploading
                    ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: Colors.green),
                )
                    : ElevatedButton(
                  onPressed: uploadFile,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child:  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(context.localizations.upload_file),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${context.localizations.total_files}: ${uploadedFiles.length}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
                Expanded(
                  child: isLoadingFiles
                      ? ListView.separated(
                    itemCount: 5,
                    itemBuilder: (context, index) =>
                    const NewsCardSkelton(),
                    separatorBuilder: (context, index) =>
                    const SizedBox(height: 16.0),
                  )
                      : isDeleting
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                    itemCount: uploadedFiles.length,
                    itemBuilder: (context, index) {
                      final file = uploadedFiles[index];
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
                            '${file['date'].toString()}\nCategory: ${file['category']}',
                            style: const TextStyle(
                                color: Colors.black54),
                          ),
                          trailing:   Tooltip(message: 'حذف',
                            child: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () => deleteFile(file['ref']),
                            ),
                          ),

                        ),
                      );
                    },
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

class NotificationsScreen extends StatelessWidget {
  final List<String> notifications;
  final VoidCallback onNotificationsViewed;

  const NotificationsScreen(
      {super.key,
        required this.notifications,
        required this.onNotificationsViewed});

  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNotificationsViewed();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body:
       ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return
            ListTile(
            title: Text(notifications[index]),
          );
        },
      ),
    );
  }
}

class NewsCardSkelton extends StatelessWidget {
  const NewsCardSkelton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Skeleton(height: 120, width: 120),
        SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: 80),
              SizedBox(height: 16.0 / 2),
              Skeleton(),
              SizedBox(height: 16.0 / 2),
              Skeleton(),
              SizedBox(height: 16.0 / 2),
              Row(
                children: [
                  Expanded(
                    child: Skeleton(),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: Skeleton(),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}

class Skeleton extends StatelessWidget {
  const Skeleton({Key? key, this.height, this.width}) : super(key: key);

  final double? height, width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.all(16.0 / 2),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: const BorderRadius.all(Radius.circular(16.0))),
    );
  }
}