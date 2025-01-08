import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:untitled4/components/context-extenssion.dart';

class UserProfilesScreen extends StatelessWidget {
  const UserProfilesScreen({super.key});

  Future<List<Map<String, dynamic>>> fetchUserProfiles() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('profiles').get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.localizations.user_profiles,
          style: TextStyle(
            color: Colors.yellow[700],
            fontWeight: FontWeight.bold,
          ),
        ),
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
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/admin');
                },
                icon: const Icon(Icons.arrow_forward_ios_outlined,
                    color: Colors.black),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          // color: Colors.white,
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchUserProfiles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading profiles'));
                } else {
                  final profiles = snapshot.data!;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          // color: Colors.white,
                          child: DataTable(
                            columnSpacing: 20.0,
                            headingRowColor: MaterialStateColor.resolveWith(
                                (states) => Colors.teal.shade100),
                            columns: const [
                              DataColumn(
                                  label: Text('Name',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Email',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Phone',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('LastSeen',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Location',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Street',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: profiles.map((profile) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(profile['name'] ?? 'No Name')),
                                  DataCell(
                                      Text(profile['email'] ?? 'No Email')),
                                  DataCell(
                                      Text(profile['phone'] ?? 'No Phone')),
                                  DataCell(Text(profile['lastSeen'] != null
                                      ? (profile['lastSeen'] as Timestamp)
                                          .toDate()
                                          .toString()
                                      : 'No Date')),
                                  DataCell(
                                      Text(profile['city'] ?? 'No Location')),
                                  DataCell(
                                      Text(profile['street'] ?? 'No Street')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
