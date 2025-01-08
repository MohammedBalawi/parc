import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled4/components/context-extenssion.dart';


class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  _ProfileFormScreenState createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  Uint8List? _imageBytes;
  bool isLoading = false;
  String successMessage = '';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<String?> _uploadImage(Uint8List bytes) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putData(bytes);

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL(); // Return the image URL
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _uploadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      await _deleteOldProfiles(user.email);

      String? imageUrl;
      if (_imageBytes != null) {
        imageUrl =
            await _uploadImage(_imageBytes!); // Upload image and get the URL
      }

      final profileData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'email': user.email,
        'imageUrl': imageUrl,
        'lastSeen': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('profiles').add(profileData);

      setState(() {
        successMessage = 'Data uploaded successfully!';
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileDetailsScreen(),
        ),
      );
    } catch (e) {
      setState(() {
        successMessage = 'Failed to upload data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteOldProfiles(String? email) async {
    try {
      final profilesRef = FirebaseFirestore.instance.collection('profiles');
      final querySnapshot =
          await profilesRef.where('email', isEqualTo: email).get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting old profiles: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(context.localizations.profile_details,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.yellow[700],
        centerTitle: true,
        actions: [
          Tooltip(message: 'الرجوع',
            child: IconButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              icon: const Icon(Icons.arrow_forward_ios_outlined),
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_imageBytes != null)
                        Image.memory(_imageBytes!,
                            height: 150, width: 150, fit: BoxFit.cover),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _pickImage,
                        child:  Text(context.localizations.select_image),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              decoration:  InputDecoration(
                                labelText: context.localizations.name,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _phoneController,
                              decoration:  InputDecoration(
                                labelText: context.localizations.phone,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _streetController,
                              decoration:  InputDecoration(
                                labelText: context.localizations.street,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _cityController,
                              decoration:  InputDecoration(
                                labelText: context.localizations.city,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _uploadData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  :  Text(context.localizations.update_profile,
                                      style: TextStyle(color: Colors.white)),
                            ),
                            if (successMessage.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(successMessage,
                                  style: const TextStyle(
                                      color: Colors.green, fontSize: 16)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  Future<Map<String, dynamic>> _fetchData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception("No data found");
    }

    return snapshot.docs.first.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(context.localizations.profile_details),
        backgroundColor: Colors.yellow[700],
        centerTitle: true,
        actions: [
          Tooltip(message: 'تعديل',
            child: IconButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/profile');
              },
              icon: const Icon(Icons.edit),
            ),
          ),

        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found'));
          } else {
            final profileData = snapshot.data!;
            final lastSeen = profileData['lastSeen']?.toDate();
            return Center(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.all(16.0),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profileData['imageUrl'] != null)
                      Image.network(
                        profileData['imageUrl'],
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 10),
                    Text('${context.localizations.name} : ${profileData['name']}',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text('${context.localizations.phone} : ${profileData['phone']}',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text('${context.localizations.street} : ${profileData['street']}',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text('${context.localizations.city} : ${profileData['city']}',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text('${context.localizations.email} : ${profileData['email']}',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    if (lastSeen != null)
                      Text('${context.localizations.last_login} : ${lastSeen.toLocal()}',
                          style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
