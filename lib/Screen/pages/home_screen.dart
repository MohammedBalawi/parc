import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled4/components/context-extenssion.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/language_provider.dart';
import '../../components/shared.dart';
import '../Chat/chat_screen.dart';
import '../Chat/privet_chat_screen.dart';
import '../Favorites/favorites_screen.dart';
import '../Files/send_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isUploading = false;
  bool isDeleting = false;
  bool isLoadingFiles = true;
  Map<String, List<Map<String, dynamic>>> categorizedFiles = {};
  String selectedCategory = '';
  String searchQuery = '';
  String searchFilter = 'name';
  String? userEmail;
  String? userName;
  bool hasUnreadMessages = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _language;

  @override
  void initState() {
    super.initState();
    userEmail = FirebaseAuth.instance.currentUser?.email;
    fetchUserData();
    fetchUploadedFiles();
    checkUnreadMessages();
    _language =
        SharedPrefController().getValueFor<String>(Key: PreKey.language.name) ??
            'en';
  }

  Future<void> fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final profileSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .where('email', isEqualTo: user.email)
          .get();

      if (profileSnapshot.docs.isNotEmpty) {
        setState(() {
          userName = profileSnapshot.docs.first['name'];
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> fetchUploadedFiles() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ListResult result =
    await FirebaseStorage.instance.ref().child('uploads').listAll();

    Map<String, List<Map<String, dynamic>>> files = {};

    for (var ref in result.items) {
      final metadata = await ref.getMetadata();
      String category = metadata.customMetadata?['category'] ?? 'فارغ';
      files.putIfAbsent(category, () => []);
      if (metadata.customMetadata?['uploader_email'] == user.email!) {
        files[category]!.add({
          'name': ref.name,
          'date': metadata.timeCreated,
          'ref': ref,
          'category': category,
          'rowCount': metadata.customMetadata?['rowCount'] ?? 'Unknown',
          'time':
          metadata.timeCreated?.toLocal().toString().split(' ')[1] ?? '',
        });
      }
    }

    setState(() {
      categorizedFiles = files.map((key, value) {
        value.sort((a, b) => b['date'].compareTo(a['date']));
        return MapEntry(key, value);
      });
      isLoadingFiles = false;
    });
  }

  List<Map<String, dynamic>> getFilteredFiles() {
    if (searchQuery.isEmpty) {
      return categorizedFiles[selectedCategory] ?? [];
    }
    return (categorizedFiles[selectedCategory] ?? []).where((file) {
      return file[searchFilter]
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> checkUnreadMessages() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('sender', isNotEqualTo: currentUser.email)
        .where('isRead', isEqualTo: false)
        .get();

    setState(() {
      hasUnreadMessages = messagesSnapshot.docs.isNotEmpty;
    });
  }

  // Future<void> markMessagesAsRead(BuildContext context) async {
  //   final currentUser = FirebaseAuth.instance.currentUser;
  //   if (currentUser == null) return;
  //
  //   final messagesSnapshot = await FirebaseFirestore.instance
  //       .collection('messages')
  //       .where('sender', isNotEqualTo: currentUser.email)
  //       .where('isRead', isEqualTo: false)
  //       .get();
  //
  //   for (var doc in messagesSnapshot.docs) {
  //     await doc.reference.update({'isRead': true});
  //   }
  //
  //   setState(() {
  //     hasUnreadMessages = false;
  //   });
  // }

  Widget getFileIcon(String fileName) {
    if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
      return const Icon(Icons.table_chart, color: Colors.green);
    } else if (fileName.endsWith('.pdf')) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.png')) {
      return const Icon(Icons.image, color: Colors.grey);
    } else {
      return const Icon(Icons.file_copy, color: Colors.blueAccent);
    }
  }

  Future<void> downloadFile(Reference ref, BuildContext context) async {
    try {
      final url = await ref.getDownloadURL();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Download Link'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Click the link to download the file:'),
                SelectableText('Download file .',
                    style: TextStyle(color: Colors.blue)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _launchURL(url);
                  Navigator.of(context).pop();
                },
                child: const Text('Download'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching the download link: $e')),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.localizations.weal,
            style: TextStyle(
                color: Colors.yellow[700], fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Tooltip(message: 'الدردشة الجماعية',
          child:   _buildIconButton(Icons.mark_unread_chat_alt_outlined, '/chat'),
        ),
          Tooltip(message: 'البحث',
            child:      _buildIconButton(Icons.search, '/search'),
          ),
          Tooltip(message: 'رفع الملفات',
            child:   _buildIconButton(Icons.add, '/upload'),
          ),

        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/image/parc.jpg', fit: BoxFit.cover),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.yellow[700]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(context.localizations.menu,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                  Text('${context.localizations.email}: $userEmail',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('${context.localizations.eng}:$userName' ?? 'No name',
                      style:
                      const TextStyle(color: Colors.white, fontSize: 15)),
                ],
              ),
            ),
            Tooltip(message: 'المعلومات الشخصية',
              child: ListTile(
                leading:
                const Icon(Icons.info_outline_rounded, color: Colors.black),
                title:  Text(context.localizations.info, style: const TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/edit');
                },
              ),
            ),
            Tooltip(message: 'الملفات الوارده',
              child: ListTile(
                leading: const Icon(Icons.move_to_inbox_outlined,
                    color: Colors.black),
                title:
                Text(context.localizations.in_box, style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SendScreen(email: userEmail!),
                    ),
                  );
                },
              ),
            ),
            Tooltip(message: 'الدردشة',
              child: MessageListTile(userEmail:userEmail! ,),
            ),
            Tooltip(message: 'الفواتير',
              child: ListTile(
                leading:
                const Icon(Icons.inventory_outlined, color: Colors.black),
                title:
                Text(context.localizations.invoice, style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/invoice');
                },
              ),
            ),
            Tooltip(message: 'الخريطة',
              child:  ListTile(
                leading: const Icon(Icons.map_outlined,
                    color: Colors.black),
                title:  Text(context.localizations.map,
                    style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/map');
                },
              ),
            ),
            Tooltip(message: 'المفضله',
              child:   ListTile(
                leading: const Icon(Icons.favorite_outline_rounded,
                    color: Colors.black),
                title:  Text(context.localizations.file,
                    style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/FileUploadScreen');
                },
              ),
            ),
            Tooltip(message: 'اللغة',
              child:  ListTile(
                leading: const Icon(
                  Icons.language,
                  color: Colors.black,
                ),
                title:
                Text(context.localizations.language, style: TextStyle(color: Colors.black)),
                onTap: () {
                  _showLanguageBottomSheet();
                },
              ),
            ),
            Tooltip(message: 'تسجيل الخروج',
              child:  ListTile(
                leading: const Icon(Icons.logout_outlined, color: Colors.black),
                title:
                Text(context.localizations.logout, style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String route) {
    return Consumer(
      builder: (context, messageProvider, child) {


        Color? iconColor = Colors.yellow[700];

        return Padding(
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
            child: IconButton(
              icon: Icon(icon, color: iconColor),
              onPressed: () async {
                if (icon == Icons.mark_unread_chat_alt_outlined) {
                }
                Navigator.pushReplacementNamed(context, route);
              },
            ),
          ),
        );
      },
    );
  }


  Widget buildContent() {
    int visibleFileCount = getFilteredFiles().length;
    return Row(
      children: [
        Container(
          width: 100,
          color: Colors.grey[200],
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
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
                          child: Icon(Icons.folder,
                              size: 30, color: Colors.yellow[700]),
                        ),
                        const SizedBox(height: 5),
                        Text(category,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
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
                                offset: const Offset(0, 3)),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: context.localizations.search,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none),
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
                            child: Text(context.localizations.name,
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DropdownMenuItem(
                            value: 'date',
                            child: Text(context.localizations.date,
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DropdownMenuItem(
                            value: 'category',
                            child: Text(context.localizations.category,
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DropdownMenuItem(
                            value: 'time',
                            child: Text(context.localizations.time,
                                style: TextStyle(fontWeight: FontWeight.bold))),
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${context.localizations.total_files}: $visibleFileCount',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              const SizedBox(height: 10),
              // Expanded(
              //     child: isLoadingFiles
              //         ? ListView.separated(
              //       itemCount: 5,
              //       itemBuilder: (context, index) =>
              //       const NewsCardSkelton(),
              //       separatorBuilder: (context, index) =>
              //       const SizedBox(height: 16.0),
              //     )
              //         : ListView(
              //       children: getFilteredFiles().map((file) {
              //         return Container(
              //           margin: const EdgeInsets.symmetric(
              //               vertical: 5.0, horizontal: 10.0),
              //           padding: const EdgeInsets.all(10.0),
              //           decoration: BoxDecoration(
              //             color: Colors.white,
              //             borderRadius: BorderRadius.circular(10.0),
              //             boxShadow: [
              //               BoxShadow(
              //                 color: Colors.grey.withOpacity(0.5),
              //                 spreadRadius: 2,
              //                 blurRadius: 5,
              //                 offset: const Offset(0, 3),
              //               ),
              //             ],
              //           ),
              //           child: ListTile(
              //             leading: getFileIcon(file['name']),
              //             title: Text(file['name'],
              //                 style: const TextStyle(
              //                     fontWeight: FontWeight.bold,
              //                     color: Colors.black87)),
              //             subtitle: Text(
              //               '${file['date'].toString()}\nCategory: ${file['category']}\nTime: ${file['time']}',
              //               style:
              //               const TextStyle(color: Colors.black54),
              //             ),
              //             trailing: IconButton(
              //               icon: const Icon(Icons.download,
              //                   color: Colors.green),
              //               onPressed: () {
              //                 downloadFile(file['ref'], context);
              //               },
              //             ),
              //           ),
              //         );
              //       }).toList(),
              //     )),
              Expanded(
                child: isLoadingFiles
                    ? ListView.separated(
                  itemCount: 5,
                  itemBuilder: (context, index) => const NewsCardSkelton(),
                  separatorBuilder: (context, index) => const SizedBox(height: 16.0),
                )
                    : ListView.builder(
                  itemCount: getFilteredFiles().length,
                  itemBuilder: (context, index) {
                    final file = getFilteredFiles()[index];
                    final previousFile =
                    index > 0 ? getFilteredFiles()[index - 1] : null;

                    // التأكد من أن التاريخ هو كائن DateTime
                    final currentFileDate = file['date'] is DateTime
                        ? file['date']
                        : DateTime.parse(file['date']);
                    final previousFileDate = previousFile != null && previousFile['date'] is DateTime
                        ? previousFile['date']
                        : previousFile != null
                        ? DateTime.parse(previousFile['date'])
                        : null;

                    // تحقق مما إذا كان الشهر والسنة قد تغيرا
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
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
                            title: Text(file['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: Colors.black87)),
                            subtitle: Text(
                              '${currentFileDate.toString()}\nCategory: ${file['category']}\nTime: ${file['time']}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing:  Tooltip(message: 'تنزيل',
                              child: IconButton(
                                icon: const Icon(Icons.download, color: Colors.green),
                                onPressed: () {
                                  downloadFile(file['ref'], context);
                                },
                              ),
                            ),

                          ),
                        ),
                      ],
                    );
                  },
                )

              ),

            ],
          ),
        ),
      ],
    );
  }
}

class MessageListTile extends StatefulWidget {
  final String userEmail;

  const MessageListTile({required this.userEmail, Key? key}) : super(key: key);

  @override
  _MessageListTileState createState() => _MessageListTileState();
}

class _MessageListTileState extends State<MessageListTile> {
  int unreadMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    checkUnreadMessages();
  }

  Future<void> checkUnreadMessages() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    // الاستماع إلى الرسائل غير المقروءة
    FirebaseFirestore.instance
        .collection('chat_p')
        .where('receiver', isEqualTo: currentUser.email)
        .where('isNewMessage', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        unreadMessagesCount = snapshot.docs.length; // تحديث عدد الرسائل غير المقروءة
      });
    });
  }

  Future<void> markMessagesAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('chat_p')
        .where('receiver', isEqualTo: currentUser.email)
        .where('isNewMessage', isEqualTo: true)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.update({'isNewMessage': false});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          const Icon(
            Icons.mail_outline_outlined,
            color: Colors.black,
            size: 30,
          ),
          if (unreadMessagesCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadMessagesCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        context.localizations.message,
        style: TextStyle(color: Colors.black),
      ),
      onTap: () async {
        await markMessagesAsRead();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrivetChatScreen(
              userEmail: widget.userEmail,
            ),
          ),
        );
      },
    );
  }
}
