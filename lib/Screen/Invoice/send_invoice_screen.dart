// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:launch_app/components/context-extenssion.dart';
//
// class FirebaseDisplayScreen extends StatefulWidget {
//   final String userEmail;
//
//   const FirebaseDisplayScreen({super.key, required this.userEmail});
//
//   @override
//   _FirebaseDisplayScreenState createState() => _FirebaseDisplayScreenState();
// }
//
// class _FirebaseDisplayScreenState extends State<FirebaseDisplayScreen> {
//   final _firestore = FirebaseFirestore.instance;
//   late Stream<QuerySnapshot> _stream;
//
//   @override
//   void initState() {
//     super.initState();
//     _stream = _firestore
//         .collection('names')
//         .orderBy('date', descending: true)
//         .snapshots();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title:  Text(context.localizations.invoice,
//             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
//         backgroundColor: Colors.yellow[700],
//         elevation: 10.0,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _stream,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No data found'));
//           }
//
//           final documents = snapshot.data!.docs;
//           return ListView.builder(
//             itemCount: documents.length,
//             itemBuilder: (context, index) {
//               final doc = documents[index];
//               final data = doc.data() as Map<String, dynamic>;
//               final firstName = data['firstName'];
//               final secondName = data['secondName'];
//               final thirdName = data['thirdName'];
//               final fourName = data['camp1'];
//               final fiveName = data['camp2'];
//               final coordinates1 = data['coordinates1'];
//               final admin1 = data['admin1'];
//               final coordinates2 = data['coordinates2'];
//               final admin2 = data['admin2'];
//               final date = data['date'];
//               final senderEmail = data['senderEmail'];
//
//               if (widget.userEmail == senderEmail) {
//                 return Card(
//                   margin: const EdgeInsets.symmetric(
//                       vertical: 8.0, horizontal: 16.0),
//                   elevation: 6.0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   shadowColor: Colors.black54,
//                   child: Padding(
//                     padding:  EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildListText('💼 ${context.localizations.quantity_received}: $firstName'),
//                         _buildListText('📦 ${context.localizations.number_of_recipients}: $secondName'),
//                         _buildListText('🎁 ${context.localizations.product_received}: $thirdName'),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//
//                             _buildListText('🏕️ ${context.localizations.camp_1}: $fourName'),
//                             _buildListText('📍 ${context.localizations.coordinates_1}: $coordinates1'),
//                             _buildListText('👨🏻 ${context.localizations.admin_1}: $admin1'),
//                           ],
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             _buildListText('🏕️ ${context.localizations.camp_2}: $fiveName'),
//                             _buildListText('📍 ${context.localizations.coordinates_2}: $coordinates2'),
//                             _buildListText('👨🏻 ${context.localizations.admin_2}: $admin2'),
//                           ],),
//
//                         _buildListText('🕒 ${context.localizations.date}: $date'),
//                         _buildListText('📧 ${context.localizations.uploader_email}: $senderEmail',
//                             color: Colors.blueAccent),
//                       ],
//                     ),
//                   ),
//                 );
//               }
//
//               return Container();
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildListText(String text, {Color color = Colors.black}) {
//     return Padding(
//       padding:  EdgeInsets.symmetric(vertical: 8.0),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//           color: color,
//         ),
//       ),
//     );
//   }
// }
//
//

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseDisplayScreen extends StatefulWidget {
  final String userEmail;

  const FirebaseDisplayScreen({super.key, required this.userEmail});

  @override
  _FirebaseDisplayScreenState createState() => _FirebaseDisplayScreenState();
}

class _FirebaseDisplayScreenState extends State<FirebaseDisplayScreen> {
  final _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _firestore
        .collection('names')
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Invoice',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.yellow[700],
        elevation: 10.0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No data found'));
          }

          final documents = snapshot.data!.docs;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final data = doc.data() as Map<String, dynamic>;
              final firstName = data['firstName'] ?? 'N/A';
              final secondName = data['secondName'] ?? 'N/A';
              final thirdName = data['thirdName'] ?? 'N/A';
              final camp1 = data['camp1'] ?? 'N/A';
              final camp2 = data['camp2'] ?? 'N/A';
              final coordinates1 = data['coordinates1'] ?? 'N/A';
              final coordinates2 = data['coordinates2'] ?? 'N/A';
              final admin1 = data['admin1'] ?? 'N/A';
              final admin2 = data['admin2'] ?? 'N/A';
              final date = data['date'] ?? 'N/A';
              final senderEmail = data['senderEmail'] ?? 'N/A';

              if (widget.userEmail == senderEmail) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 16.0),
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  shadowColor: Colors.black38,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildListHeader('General Information'),
                        const SizedBox(height: 8.0),
                        _buildListText('💼 Quantity Received : ', firstName),
                        _buildListText('📦 Number of Recipients : ', secondName),
                        _buildListText('🎁 Product Received : ', thirdName),
                        const SizedBox(height: 16.0),
                        _buildListHeader('Camp 1 Details'),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            _buildDetailItem('🏕️ Camp : ', camp1),
                            _buildDetailItem('📍 Coordinates : ', coordinates1),
                            _buildDetailItem('👨🏻 Admin : ', admin1),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        _buildListHeader('Camp 2 Details'),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            _buildDetailItem('🏕️ Camp : ', camp2),
                            _buildDetailItem('📍 Coordinates : ', coordinates2),
                            _buildDetailItem('👨🏻 Admin : ', admin2),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        _buildListHeader('Additional Information'),
                        const SizedBox(height: 8.0),
                        _buildListText('🕒 Date : ', date),
                        _buildListText('📧 Uploader Email : ', senderEmail,
                            color: Colors.blueAccent),
                      ],
                    ),
                  ),
                );
              }

              return Container();
            },
          );
        },
      ),
    );
  }

  Widget _buildListHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildListText(String label, String value, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
