import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:untitled4/components/context-extenssion.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool isUploading = false;
  bool isDeleting = false;
  bool isLoadingFiles = true;
  bool isSearchVisible = false;
  List<Map<String, dynamic>> uploadedFiles = [];
  List<Map<String, dynamic>> filteredFiles = [];
  List<Map<String, dynamic>> selectedFiles = [];
  final TextEditingController _searchController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;
  User? user;
  String userId = '';

  @override
  void initState() {
    super.initState();
    _getUserId();
    fetchUploadedFiles();
  }

  void _getUserId() {
    user = auth.currentUser;
    setState(() {
      userId = user?.uid ?? '';
    });
  }

  Future<void> fetchUploadedFiles() async {
    if (user == null) return;

    final email = user!.email;

    final ListResult result =
        await FirebaseStorage.instance.ref().child('uploads').listAll();

    List<Map<String, dynamic>> files = [];

    for (var ref in result.items) {
      final metadata = await ref.getMetadata();

      if (metadata.customMetadata?['uploader_email'] == user?.email) {
        files.add({
          'name': ref.name,
          'path': ref.fullPath,
          'date': metadata.timeCreated,
          'category': metadata.customMetadata?['category'] ?? 'Unknown',
          'rowCount': metadata.customMetadata?['rowCount'] ?? 'Unknown',
          'selected': false,
        });
      }
    }

    files.sort((a, b) => b['date'].compareTo(a['date']));

    setState(() {
      uploadedFiles = files;
      filteredFiles = files;
      isLoadingFiles = false;
    });
  }

  void filterFiles(String query) {
    final filtered = uploadedFiles.where((file) {
      final name = file['name'].toLowerCase();
      final category = file['category'].toLowerCase();
      final date = file['date'].toString().toLowerCase();
      final rowCount = file['rowCount'].toString().toLowerCase();
      final searchQuery = query.toLowerCase();

      return name.contains(searchQuery) ||
          category.contains(searchQuery) ||
          date.contains(searchQuery) ||
          rowCount.contains(searchQuery);
    }).toList();

    setState(() {
      filteredFiles = filtered;
    });
  }

  Future<void> deleteFile(Reference ref) async {
    setState(() {
      isDeleting = true;
    });
    try {
      await ref.delete();
      fetchUploadedFiles();
    } catch (e) {
      print('Error deleting file: $e');
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
      return const Icon(Icons.wordpress_rounded, color: Colors.blueAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(context.localizations.search,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
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
              child:  Tooltip(message: 'البحث',
                child: IconButton(
                  icon: Icon(Icons.search, color: Colors.yellow[700]),
                  onPressed: () {
                    setState(() {
                      isSearchVisible = !isSearchVisible;
                    });
                  },
                ),
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
              child:  Tooltip(message: 'الرجوع',
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
                if (isSearchVisible)
                  Tooltip(message: 'البحث',
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration:  InputDecoration(
                          labelText: context.localizations.search,
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.search),
                        ),
                        onChanged: filterFiles,
                      ),
                    ),
                  ),

                if (isUploading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${context.localizations.total_files}: ${filteredFiles.length}',
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
                              itemCount: filteredFiles.length,
                              itemBuilder: (context, index) {
                                final file = filteredFiles[index];
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
                                  child: CheckboxListTile(
                                    value: file['selected'],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        file['selected'] = value ?? false;
                                        if (value == true) {
                                          selectedFiles.add(file);
                                        } else {
                                          selectedFiles.remove(file);
                                        }
                                      });
                                    },
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
                                    secondary: getFileIcon(file['name']),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                );
                              },
                            ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: selectedFiles.isNotEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectedFilesScreen(
                                    files: selectedFiles, userId: userId),
                              ),
                            );
                          }
                        : null,
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        'Move to New Screen',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
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
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
      ),
    );
  }
}

class SelectedFilesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> files;
  final String userId;

  SelectedFilesScreen({required this.files, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: const Text(
          'Selected Files',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return Card(
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file,
                          color: Colors.blue),
                      title: Text(
                        file['name'] ?? 'Unnamed File',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${file['date'] ?? 'Unknown'}'),
                          Text(
                              'Category: ${file['category'] ?? 'Uncategorized'}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.download, color: Colors.green),
                            onPressed: () {
                              downloadFile(file['ref'], context);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {
                              _showFileDetails(context, file);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> downloadFile(Reference? ref, BuildContext context) async {
    if (ref == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected for download')),
      );
      return;
    }

    try {
      final url = await ref.getDownloadURL();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Download Link'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Click the link to download the file:'),
                SelectableText(url, style: const TextStyle(color: Colors.blue)),
                // Display the link
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _launchURL(
                      url);
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
        SnackBar(content: Text('Error fetching download link: $e')),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(
          url);
    } else {
      throw 'Could not launch $url'; // Handle any errors that occur
    }
  }

  void _showResultDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showFileDetails(BuildContext context, Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(file['name'] ?? 'Unnamed File'),
          content: const Text('Details about the file...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
