import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:untitled4/components/context-extenssion.dart';
import 'package:url_launcher/url_launcher.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  _FavoritesState createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  bool isUploading = false;
  bool isDeleting = false;
  bool isLoadingFiles = true;
  List<Map<String, dynamic>> uploadedFiles = [];
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    fetchUploadedFiles();
  }

  Future<void> uploadFile() async {
    String? category = await showDialog<String>(
      context: context,
      builder: (context) {
        return
        SimpleDialog(
          title:  Text(context.localizations.select_category),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'WFP'),
              child: const Text('WFP'),
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

    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    setState(() {
      isUploading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      Uint8List fileBytes = result.files.single.bytes as Uint8List;
      String fileName = result.files.single.name;

      final storageRef = FirebaseStorage.instance.ref().child('up/$fileName');

      SettableMetadata metadata = SettableMetadata(customMetadata: {
        'category': category,
        'uploader_email': user.email!,
      });

      await storageRef.putData(fileBytes, metadata);

      await fetchUploadedFiles();

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
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  // Future<void> fetchUploadedFiles() async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;
  //
  //   final ListResult result =
  //       await FirebaseStorage.instance.ref().child('up').listAll();
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

  Future<void> fetchUploadedFiles() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ListResult result =
    await FirebaseStorage.instance.ref().child('up').listAll();

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
            title: const Text('Deleted'),
            content: const Text('File deleted successfully'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
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
            title: const Text('Error'),
            content: Text('Error deleting file: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
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

  void shareFile(String fileUrl) {
    Share.share(fileUrl);
  }

  Future<void> downloadFile(Reference ref) async {
    try {
      final String fileUrl = await ref.getDownloadURL();

      if (await canLaunch(fileUrl)) {
        await launch(fileUrl);
      } else {
        throw 'Could not launch $fileUrl';
      }
    } catch (e) {
      print('Error downloading file: $e');
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
        backgroundColor: Colors.yellow[700],
        title:  Text(
          context.localizations.file,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
              child:   Tooltip(message: 'الرجوع',
                child:    IconButton(
                  onPressed: () async {
                    bool isAdmin = await checkIfUserIsAdmin();
                    if (isAdmin) {
                      Navigator.pushReplacementNamed(context, '/admin');
                    } else {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  icon: Icon(Icons.arrow_forward_ios_outlined,
                      color: Colors.yellow[700]),
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
            decoration: BoxDecoration(color: Colors.black.withOpacity(0)),
            child: Column(
              children: [
                const SizedBox(height: 10),
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
                                      '${file['date'].toString()}\nCategory: ${file['category']}\nRows: ${file['rowCount']}',
                                      style: const TextStyle(
                                          color: Colors.black54),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Tooltip(message: 'تنزيل',
                                          child: IconButton(
                                            icon: const Icon(
                                                Icons.download_rounded,
                                                color: Colors.blue),
                                            onPressed: () {
                                              final fileUrl = file['ref'];
                                              downloadFile(fileUrl);
                                            },
                                          ),
                                        ),
                                        Tooltip(message: 'مشاركة',
                                          child: IconButton(
                                            icon: const Icon(Icons.share,
                                                color: Colors.blue),
                                            onPressed: () {
                                              final fileUrl = file['ref']
                                                  .getDownloadURL()
                                                  .toString();
                                              shareFile(
                                                  fileUrl); // Share file URL
                                            },
                                          ),
                                        ),
                                        Tooltip(message: 'حذف',
                                          child: IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () =>
                                                deleteFile(file['ref']),
                                          ),
                                        ),

                                      ],
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

class NewsCardSkelton extends StatelessWidget {
  const NewsCardSkelton({Key? key}) : super(key: key);

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
                  Expanded(child: Skeleton()),
                  SizedBox(width: 16.0),
                  Expanded(child: Skeleton()),
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
