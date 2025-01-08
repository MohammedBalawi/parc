import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled4/components/context-extenssion.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class FileScreen extends StatefulWidget {
  const FileScreen({super.key});

  @override
  _FileScreenState createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  bool isUploading = false;
  bool isDownloading = false;
  bool isLoadingFiles = true;
  List<Map<String, dynamic>> uploadedFiles = [];
  String selectedCategory = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchAllFiles();
  }
  //
  // Future<void> fetchAllFiles() async {
  //   setState(() {
  //     isLoadingFiles = true;
  //   });
  //
  //   List<Map<String, dynamic>> files = [];
  //
  //   final ListResult uploadResult =
  //       await FirebaseStorage.instance.ref().child('uploads').listAll();
  //   files.addAll(await _fetchFilesFromResult(uploadResult, 'uploads'));
  //
  //   final ListResult downloadResult =
  //       await FirebaseStorage.instance.ref().child('download').listAll();
  //   files.addAll(await _fetchFilesFromResult(downloadResult, 'download'));
  //
  //   files.sort((a, b) => b['date'].compareTo(a['date']));
  //
  //   setState(() {
  //     uploadedFiles = files;
  //     isLoadingFiles = false;
  //   });
  // }
  //
  // Future<List<Map<String, dynamic>>> _fetchFilesFromResult(
  //     ListResult result, String source) async {
  //   List<Map<String, dynamic>> files = [];
  //   for (var ref in result.items) {
  //     final metadata = await ref.getMetadata();
  //     files.add({
  //       'name': ref.name,
  //       'date': metadata.timeCreated,
  //       'ref': ref,
  //       'source': source,
  //       'category': metadata.customMetadata?['category'] ?? 'Unknown',
  //       'uploader_email':
  //           metadata.customMetadata?['uploader_email'] ?? 'Unknown',
  //     });
  //   }
  //   return files;
  // }

  Future<void> fetchAllFiles() async {
    try {
      setState(() {
        isLoadingFiles = true;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User is not logged in.");
      }

      List<Map<String, dynamic>> files = [];

      // 📂 **جلب الملفات من مجلد 'uploads'**
      final ListResult uploadResult =
      await FirebaseStorage.instance.ref().child('uploads').listAll();
      files.addAll(await _fetchFilesFromResult(uploadResult, 'uploads'));

      // 📂 **جلب الملفات من مجلد 'download'**
      final ListResult downloadResult =
      await FirebaseStorage.instance.ref().child('download').listAll();
      files.addAll(await _fetchFilesFromResult(downloadResult, 'download'));

      // **🔹 ترتيب الملفات حسب تاريخ الرفع (الأحدث أولًا)**
      files.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        uploadedFiles = files;
        isLoadingFiles = false;
      });
    } catch (e) {
      setState(() {
        isLoadingFiles = false;
      });
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(context.localizations.error),
            content: Text("Error fetching files: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.localizations.ok),
              ),
            ],
          );
        },
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFilesFromResult(
      ListResult result, String source) async {
    List<Map<String, dynamic>> files = [];
    for (var ref in result.items) {
      final metadata = await ref.getMetadata();
      files.add({
        'name': ref.name,
        'date': metadata.timeCreated,
        'ref': ref,
        'source': source,
        'category': metadata.customMetadata?['category'] ?? 'Unknown',
        'uploader_email': metadata.customMetadata?['uploader_email'] ?? 'Unknown',
      });
    }
    return files;
  }
  List<Map<String, dynamic>> getFilteredFiles() {
    return uploadedFiles.where((file) {
      final isInCategory =
          file['category'] == selectedCategory || selectedCategory.isEmpty;
      final matchesQuery = searchQuery.isEmpty ||
          file.values.any((value) {
            return value
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase());
          });
      return isInCategory && matchesQuery;
    }).toList();
  }
  Future<void> downloadFile(Reference ref) async {
    setState(() {
      isDownloading = true;
    });

    try {
      final fileUrl = await ref.getDownloadURL(); // Get the file download URL

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
                // Make the link clickable
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _launchURL(fileUrl);
                  Navigator.of(context).pop();
                },
                child: const Text('Download'),
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
            content: Text('Error downloading file: $e'),
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
        isDownloading = false;
      });
    }
  }
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
  void shareFile(String fileUrl) {
    Share.share(fileUrl);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
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
                child: IconButton(
                  onPressed: () async {
                    Navigator.pushReplacementNamed(context, '/admin');
                  },
                  icon: Icon(Icons.arrow_forward_ios_outlined,
                      color: Colors.yellow[700]),
                ),
              ),

            ),
          ),
        ],
        title:  Text(context.localizations.file,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
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
                ...uploadedFiles
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
                  ],
                ),
              ),
              const SizedBox(height: 10),
              isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${context.localizations.total_files}: ${getFilteredFiles().length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
              Expanded(
                child: isLoadingFiles
                    ? const Center(child: CircularProgressIndicator())
                    : isDownloading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
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
                                    'Date: ${file['date']}\nCategory: ${file['category']}\nUploaded by: ${file['uploader_email']}\nSource: ${file['source']}',
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                  trailing:  Tooltip(message: 'تنزيل',
                                    child:  IconButton(
                                      icon: const Icon(Icons.download,
                                          color: Colors.blue),
                                      onPressed: () => downloadFile(file['ref']),
                                    ),
                                  ),

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
