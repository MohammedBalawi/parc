// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:async';
//
//
// class MapScreen extends StatefulWidget {
//   const MapScreen({super.key});
//
//   @override
//   _MapScreenState createState() => _MapScreenState();
// }
//
// class _MapScreenState extends State<MapScreen> {
//   final Completer<GoogleMapController> _controller = Completer();
//   final Set<Marker> _markers = {};
//   LatLng _initialPosition = LatLng(31.383312, 34.299018);
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Map<String, dynamic>? _selectedMarkerDetails;
//   List<String> _notes = [];
//   double width = kIsWeb ? 1100 : 300;
//   double height = kIsWeb ? 700 : 300;
//
//   final Map<String, String> _iconTypes = {
//     "مزرعة": "assets/icons/farm.jpeg",
//     "مخيم": "assets/icons/camp.jpeg",
//     "مركز طبي": "assets/icons/medical.jpeg",
//     "مؤسسة": "assets/icons/institution.jpeg",
//     "مدرسة": "assets/icons/school.jpeg",
//     "مجمع سكني": "assets/icons/residential.jpeg",
//     "خط مياه": "assets/icons/water.jpeg",
//   };
//
//   @override
//   void initState() {
//     super.initState();
//     _loadMarkers();
//
//   }
//
//
//   Future<void> _addNote() async {
//     TextEditingController _noteController = TextEditingController();
//
//     String? newNote = await showDialog<String>(
//       context: context,
//       barrierDismissible: true,
//       builder: (context) {
//         return Stack(
//           children: [
//             Align(
//               alignment: Alignment.topRight,
//               child: Padding(
//                 padding: const EdgeInsets.only( right: 16,top: 350), // مسافة من الأعلى واليمين
//                 child: Material(
//                   color: Colors.transparent,
//                   child: Container(
//                     width: 300,
//                     height: 200,
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(15),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           spreadRadius: 2,
//                           blurRadius: 10,
//                           offset: const Offset(0, 5),
//                         ),
//                       ],
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'إضافة ملاحظة جديدة',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blueGrey,
//                             ),
//                           ),
//                           TextField(
//                             controller: _noteController,
//                             decoration: InputDecoration(
//                               hintText: 'أدخل الملاحظة هنا',
//                               hintStyle: TextStyle(color: Colors.grey[400]),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                                 borderSide: BorderSide(
//                                   color: Colors.blueGrey,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: [
//                               TextButton(
//                                 onPressed: () => Navigator.of(context).pop(null),
//                                 child: Text(
//                                   'إلغاء',
//                                   style: TextStyle(color: Colors.red),
//                                 ),
//                               ),
//                               ElevatedButton(
//                                 onPressed: () {
//                                   if (_noteController.text.trim().isEmpty) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(
//                                         content:
//                                         Text('الملاحظة لا يمكن أن تكون فارغة!'),
//                                       ),
//                                     );
//                                   } else {
//                                     Navigator.of(context)
//                                         .pop(_noteController.text.trim());
//                                   }
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blueGrey,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                                 child: Text('حفظ'),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//
//
//     if (newNote == null || newNote.isEmpty) return;
//
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null || _selectedMarkerDetails == null) return;
//
//     _notes.add(newNote);
//
//     await _firestore
//         .collection('users')
//         .doc(user.uid)
//         .collection('markers')
//         .doc(_selectedMarkerDetails!['markerId'])
//         .update({
//       'additionalNotes': _notes,
//     });
//
//     setState(() {});
//   }
//
//   // Future<void> _loadMarkers() async {
//   //   final user = FirebaseAuth.instance.currentUser;
//   //   if (user == null) return;
//   //
//   //   final snapshot = await _firestore
//   //       .collection('users')
//   //       .doc(user.uid)
//   //       .collection('markers')
//   //       .get();
//   //
//   //   for (var doc in snapshot.docs) {
//   //     final data = doc.data();
//   //     final markerId = doc.id;
//   //
//   //     final marker = Marker(
//   //       markerId: MarkerId(markerId),
//   //       position: LatLng(data['latitude'], data['longitude']),
//   //       infoWindow: InfoWindow(
//   //         title: data['type'] ?? "علامة",
//   //         snippet: data['note'] ?? '',
//   //       ),
//   //       onTap: () => _showMarkerDetails(markerId),
//   //     );
//   //
//   //     setState(() {
//   //       _markers.add(marker);
//   //     });
//   //   }
//   // }
//
//   Future<void> _loadMarkers() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('markers')
//           .get();
//
//       List<Marker> tempMarkers = [];
//
//       for (var doc in snapshot.docs) {
//         final data = doc.data();
//
//         if (data.containsKey('latitude') && data.containsKey('longitude')) {
//           double? latitude = (data['latitude'] as num?)?.toDouble();
//           double? longitude = (data['longitude'] as num?)?.toDouble();
//
//           if (latitude == null || longitude == null) {
//             print("⚠️ تحذير: علامة تحتوي على موقع فارغ (ID: ${doc.id})");
//             continue;
//           }
//
//           final markerId = doc.id;
//           final marker = Marker(
//             markerId: MarkerId(markerId),
//             position: LatLng(latitude, longitude),
//             infoWindow: InfoWindow(
//               title: data['type'] ?? "علامة",
//               snippet: data['note'] ?? '',
//             ),
//             onTap: () => _showMarkerDetails(markerId),
//           );
//
//           tempMarkers.add(marker);
//         } else {
//           print("⚠️ تحذير: مستند Firestore لا يحتوي على مفاتيح الموقع المطلوبة.");
//         }
//       }
//
//       if (mounted) {
//         setState(() {
//           _markers.addAll(tempMarkers);
//         });
//       }
//     } catch (e) {
//       print("❌ خطأ أثناء تحميل العلامات: $e");
//     }
//   }
//
//
//   bool _isNoteDialogOpen = false;
//
//   Future<void> _addMarker(LatLng position) async {
//     if (_isTypeSelectorOpen) return;
//
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     Map<String, String?>? result = await _showTypeAndNoteDialog();
//     if (result == null || result['type'] == null) return;
//
//     final String selectedType = result['type']!;
//     final String? note = result['note'];
//
//     final markerId = MarkerId(DateTime.now().toString());
//     final marker = Marker(
//       markerId: markerId,
//       position: position,
//       infoWindow: InfoWindow(title: selectedType, snippet: note),
//       onTap: () => _showMarkerDetails(markerId.value),
//     );
//
//     setState(() {
//       _markers.add(marker);
//     });
//
//     await _firestore
//         .collection('users')
//         .doc(user.uid)
//         .collection('markers')
//         .doc(markerId.value)
//         .set({
//       'latitude': position.latitude,
//       'longitude': position.longitude,
//       'type': selectedType,
//       'image': _iconTypes[selectedType],
//       'note': note,
//       'files': [],
//       'additionalNotes': [],
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//   }
//
//   bool _isTypeSelectorOpen = false;
//
//   // Future<Map<String, String?>?> _showTypeAndNoteDialog() async {
//   //   if (_isTypeSelectorOpen) return null;
//   //
//   //   _isTypeSelectorOpen = true;
//   //
//   //   TextEditingController _noteController = TextEditingController();
//   //
//   //   Map<String, String?>? result = await showDialog<Map<String, String?>?>(
//   //     context: context,
//   //     barrierDismissible: false,
//   //     builder: (context) {
//   //       String? selectedType;
//   //
//   //       return StatefulBuilder(
//   //         builder: (context, setState) {
//   //           return Align(
//   //             alignment: Alignment.centerRight,
//   //             child: Material(
//   //               color: Colors.transparent,
//   //               child: Container(
//   //                 margin: EdgeInsets.only(top: 200, left: 1000),
//   //                 padding: EdgeInsets.all(16),
//   //                 decoration: BoxDecoration(
//   //                   color: Colors.white,
//   //                   borderRadius: BorderRadius.circular(16),
//   //                   boxShadow: [
//   //                     BoxShadow(
//   //                       color: Colors.black.withOpacity(0.2),
//   //                       blurRadius: 15,
//   //                       spreadRadius: 5,
//   //                       offset: Offset(5, 5),
//   //                     ),
//   //                   ],
//   //                 ),
//   //                 child: Column(
//   //                   mainAxisSize: MainAxisSize.min,
//   //                   crossAxisAlignment: CrossAxisAlignment.start,
//   //                   children: [
//   //                     const Text(
//   //                       'إضافة علامة',
//   //                       style: TextStyle(
//   //                         fontSize: 20,
//   //                         fontWeight: FontWeight.bold,
//   //                         color: Colors.black87,
//   //                       ),
//   //                     ),
//   //                     SizedBox(height: 20),
//   //                     DropdownButton<String>(
//   //                       value: selectedType,
//   //                       hint: Text('اختر نوع العلامة'),
//   //                       isExpanded: true,
//   //                       items: _iconTypes.entries.map((entry) {
//   //                         return DropdownMenuItem<String>(
//   //                           value: entry.key,
//   //                           child: Row(
//   //                             children: [
//   //                               Image.asset(entry.value, width: 40, height: 40),
//   //                               SizedBox(width: 10),
//   //                               Text(entry.key),
//   //                             ],
//   //                           ),
//   //                         );
//   //                       }).toList(),
//   //                       onChanged: (value) {
//   //                         setState(() {
//   //                           selectedType = value;
//   //                         });
//   //                       },
//   //                     ),
//   //                     SizedBox(height: 20),
//   //                     TextField(
//   //                       controller: _noteController,
//   //                       decoration: InputDecoration(
//   //                         labelText: 'أدخل الملاحظة هنا',
//   //                         border: OutlineInputBorder(
//   //                           borderRadius: BorderRadius.circular(12),
//   //                         ),
//   //                         focusedBorder: OutlineInputBorder(
//   //                           borderRadius: BorderRadius.circular(12),
//   //                           borderSide:
//   //                               const BorderSide(color: Colors.blue, width: 2),
//   //                         ),
//   //                         contentPadding: EdgeInsets.symmetric(
//   //                           vertical: 10,
//   //                           horizontal: 15,
//   //                         ),
//   //                       ),
//   //                     ),
//   //                     const SizedBox(height: 20),
//   //                     Row(
//   //                       mainAxisAlignment: MainAxisAlignment.end,
//   //                       children: [
//   //                         ElevatedButton(
//   //                           onPressed: () {
//   //                             _isTypeSelectorOpen = false;
//   //                             Navigator.of(context)
//   //                                 .pop(null);
//   //                           },
//   //                           style: ElevatedButton.styleFrom(
//   //                             backgroundColor: Colors.grey[300],
//   //                             foregroundColor: Colors.black,
//   //                             shape: RoundedRectangleBorder(
//   //                               borderRadius: BorderRadius.circular(8),
//   //                             ),
//   //                           ),
//   //                           child: Text('إلغاء'),
//   //                         ),
//   //                         SizedBox(width: 10),
//   //                         ElevatedButton(
//   //                           onPressed: () {
//   //                             if (selectedType != null) {
//   //                               _isTypeSelectorOpen =
//   //                                   false;
//   //                               Navigator.of(context).pop({
//   //                                 'type': selectedType,
//   //                                 'note': _noteController.text.trim(),
//   //                               });
//   //                             }
//   //                           },
//   //                           style: ElevatedButton.styleFrom(
//   //                             backgroundColor: Colors.blue,
//   //                             foregroundColor: Colors.white,
//   //                             shape: RoundedRectangleBorder(
//   //                               borderRadius: BorderRadius.circular(8),
//   //                             ),
//   //                           ),
//   //                           child: Text('حفظ'),
//   //                         ),
//   //                       ],
//   //                     ),
//   //                   ],
//   //                 ),
//   //               ),
//   //             ),
//   //           );
//   //         },
//   //       );
//   //     },
//   //   );
//   //
//   //   _isTypeSelectorOpen = false;
//   //   return result;
//   // }
//   Future<Map<String, String?>?> _showTypeAndNoteDialog() async {
//     if (_isTypeSelectorOpen) return null;
//
//     _isTypeSelectorOpen = true;
//
//     TextEditingController _noteController = TextEditingController();
//
//     return await showDialog<Map<String, String?>?>(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         String? selectedType;
//         bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
//
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return Align(
//               alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight, // ✅ تغيير الاتجاه
//               child: Material(
//                 color: Colors.transparent,
//                 child: Container(
//                   margin: EdgeInsets.only(
//                     top: 200,
//                     left: isArabic ? 0 : 1000,
//                     right: isArabic ? 1000 : 0,
//                   ),
//                   padding: EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.2),
//                         blurRadius: 15,
//                         spreadRadius: 5,
//                         offset: Offset(5, 5),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         isArabic ? 'إضافة علامة' : 'Add Marker',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                       DropdownButton<String>(
//                         value: selectedType,
//                         hint: Text(isArabic ? 'اختر نوع العلامة' : 'Select Marker Type'), // ✅ دعم اللغات
//                         isExpanded: true,
//                         items: _iconTypes.entries.map((entry) {
//                           return DropdownMenuItem<String>(
//                             value: entry.key,
//                             child: Row(
//                               children: [
//                                 Image.asset(entry.value, width: 40, height: 40),
//                                 SizedBox(width: 10),
//                                 Text(entry.key),
//                               ],
//                             ),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             selectedType = value;
//                           });
//                         },
//                       ),
//                       SizedBox(height: 20),
//                       TextField(
//                         controller: _noteController,
//                         decoration: InputDecoration(
//                           labelText: isArabic ? 'أدخل الملاحظة هنا' : 'Enter note here', // ✅ دعم اللغات
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(color: Colors.blue, width: 2),
//                           ),
//                           contentPadding: EdgeInsets.symmetric(
//                             vertical: 10,
//                             horizontal: 15,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           ElevatedButton(
//                             onPressed: () {
//                               _isTypeSelectorOpen = false;
//                               Navigator.of(context).pop(null);
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.grey[300],
//                               foregroundColor: Colors.black,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(isArabic ? 'إلغاء' : 'Cancel'), // ✅ دعم اللغات
//                           ),
//                           SizedBox(width: 10),
//                           ElevatedButton(
//                             onPressed: () {
//                               if (selectedType != null) {
//                                 _isTypeSelectorOpen = false;
//                                 Navigator.of(context).pop({
//                                   'type': selectedType,
//                                   'note': _noteController.text.trim(),
//                                 });
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue,
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(isArabic ? 'حفظ' : 'Save'), // ✅ دعم اللغات
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//
//   Future<void> _showMarkerDetails(String markerId) async {
//     if (_isNoteDialogOpen) return;
//
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     final doc = await _firestore
//         .collection('users')
//         .doc(user.uid)
//         .collection('markers')
//         .doc(markerId)
//         .get();
//
//     if (doc.exists) {
//       setState(() {
//         _selectedMarkerDetails = doc.data();
//         _selectedMarkerDetails?['markerId'] = markerId;
//         _notes =
//             List<String>.from(_selectedMarkerDetails?['additionalNotes'] ?? []);
//       });
//     }
//   }
//
//   // upload File
//   // Future<void> _uploadFile() async {
//   //   final result = await FilePicker.platform.pickFiles();
//   //   if (result == null || _selectedMarkerDetails == null) return;
//   //
//   //   final user = FirebaseAuth.instance.currentUser;
//   //   if (user == null) return;
//   //
//   //   final markerId = _selectedMarkerDetails!['markerId'];
//   //
//   //   if (kIsWeb) {
//   //     // الويب: استخدم `bytes`
//   //     final bytes = result.files.single.bytes;
//   //     final fileName = result.files.single.name;
//   //     if (bytes == null) return;
//   //
//   //     // رفع الملف إلى Firebase Storage
//   //     final storageRef = FirebaseStorage.instance
//   //         .ref()
//   //         .child('users/${user.uid}/markers/$markerId/$fileName');
//   //     final uploadTask = storageRef.putData(bytes);
//   //
//   //     final snapshot = await uploadTask;
//   //     final downloadUrl = await snapshot.ref.getDownloadURL();
//   //
//   //     // تخزين رابط الملف في Firestore
//   //     final List<String> updatedFiles =
//   //     List<String>.from(_selectedMarkerDetails?['files'] ?? []);
//   //     updatedFiles.add(downloadUrl);
//   //
//   //     await _firestore
//   //         .collection('users')
//   //         .doc(user.uid)
//   //         .collection('markers')
//   //         .doc(markerId)
//   //         .update({
//   //       'files': updatedFiles,
//   //     });
//   //
//   //     setState(() {
//   //       _selectedMarkerDetails?['files'] = updatedFiles;
//   //     });
//   //   } else {
//   //     // الأجهزة المحمولة: استخدم `path`
//   //     final file = File(result.files.single.path!);
//   //
//   //     // رفع الملف إلى Firebase Storage
//   //     final storageRef = FirebaseStorage.instance
//   //         .ref()
//   //         .child('users/${user.uid}/markers/$markerId/${result.files.single.name}');
//   //     final uploadTask = storageRef.putFile(file);
//   //
//   //     final snapshot = await uploadTask;
//   //     final downloadUrl = await snapshot.ref.getDownloadURL();
//   //
//   //     // تخزين رابط الملف في Firestore
//   //     final List<String> updatedFiles =
//   //     List<String>.from(_selectedMarkerDetails?['files'] ?? []);
//   //     updatedFiles.add(downloadUrl);
//   //
//   //     await _firestore
//   //         .collection('users')
//   //         .doc(user.uid)
//   //         .collection('markers')
//   //         .doc(markerId)
//   //         .update({
//   //       'files': updatedFiles,
//   //     });
//   //
//   //     setState(() {
//   //       _selectedMarkerDetails?['files'] = updatedFiles;
//   //     });
//   //   }
//   // }
//
//
//   // build File List
//
//
//   Future<void> _uploadFile() async {
//     try {
//       final result = await FilePicker.platform.pickFiles();
//
//       if (result == null || _selectedMarkerDetails == null) {
//         print("لم يتم اختيار أي ملف.");
//         return;
//       }
//
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         print("المستخدم غير مسجل دخول.");
//         return;
//       }
//
//       final markerId = _selectedMarkerDetails!['markerId'];
//       final firestore = FirebaseFirestore.instance;
//       final storage = FirebaseStorage.instance;
//
//       String fileName = result.files.single.name;
//       String storagePath = 'users/${user.uid}/markers/$markerId/$fileName';
//       Reference storageRef = storage.ref().child(storagePath);
//
//       String downloadUrl = '';
//
//       if (kIsWeb) {
//         // 📌 **للوِب**: استخدم `bytes`
//         Uint8List? fileBytes = result.files.single.bytes;
//         if (fileBytes == null) {
//           print("⚠️ لا يوجد بيانات في الملف.");
//           return;
//         }
//
//         UploadTask uploadTask = storageRef.putData(fileBytes);
//         TaskSnapshot snapshot = await uploadTask;
//         downloadUrl = await snapshot.ref.getDownloadURL();
//       } else {
//         // 📌 **لنظام Android/iOS**: استخدم `path`
//         String? filePath = result.files.single.path;
//         if (filePath == null) {
//           print("⚠️ لا يوجد مسار للملف.");
//           return;
//         }
//
//         File file = File(filePath);
//
//         // ✅ **طلب إذن الوصول إلى الملفات على Android**
//         if (Platform.isAndroid) {
//           var status = await Permission.storage.request();
//           if (status.isDenied) {
//             print("🚫 تم رفض إذن الوصول إلى الملفات.");
//             return;
//           }
//         }
//
//         UploadTask uploadTask = storageRef.putFile(file);
//         TaskSnapshot snapshot = await uploadTask;
//         downloadUrl = await snapshot.ref.getDownloadURL();
//       }
//
//       // ✅ تحديث Firestore بالرابط الجديد للملف
//       DocumentReference markerDoc = firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('markers')
//           .doc(markerId);
//
//       await markerDoc.update({
//         'files': FieldValue.arrayUnion([downloadUrl]),
//       });
//
//       setState(() {
//         _selectedMarkerDetails?['files'] =
//         List<String>.from(_selectedMarkerDetails?['files'] ?? [])..add(downloadUrl);
//       });
//
//       print("✅ تم رفع الملف بنجاح: $downloadUrl");
//     } catch (e) {
//       print("❌ حدث خطأ أثناء رفع الملف: $e");
//     }
//   }
//
//   Widget _buildFileList() {
//     final files = List<String>.from(_selectedMarkerDetails?['files'] ?? []);
//     if (files.isEmpty) {
//       return Text('لا توجد ملفات مرفقة.');
//     }
//
//     return ListView.builder(
//       itemCount: files.length,
//       shrinkWrap: true,
//       itemBuilder: (context, index) {
//         final fileUrl = files[index];
//         String i =
//             Uri.decodeComponent(fileUrl.split('?').first.split('/').last);
//
//         return ListTile(
//           title: Text(i.split('/').last), // عرض اسم الملف فقط
//           leading: Icon(Icons.file_present, color: Colors.green),
//           trailing: Row(
//             mainAxisSize: MainAxisSize.min,
//             // لضمان أن الأيقونات تأخذ مساحة صغيرة
//             children: [
//               IconButton(
//                 icon: Icon(Icons.download),
//                 onPressed: () {
//                   _downloadFile(fileUrl); // استدعاء دالة التنزيل
//                 },
//               ),
//               IconButton(
//                 icon: Icon(Icons.delete, color: Colors.red),
//                 onPressed: () {
//                   _deleteFile(fileUrl); // استدعاء دالة الحذف
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   // delete File
//   Future<void> _deleteFile(String fileUrl) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null || _selectedMarkerDetails == null) return;
//
//       final markerId = _selectedMarkerDetails!['markerId'];
//
//       // حذف الملف من Firebase Storage
//       final storageRef = FirebaseStorage.instance.refFromURL(fileUrl);
//       await storageRef.delete();
//
//       // إزالة رابط الملف من Firestore
//       final List<String> updatedFiles =
//           List<String>.from(_selectedMarkerDetails?['files'] ?? []);
//       updatedFiles.remove(fileUrl);
//
//       await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('markers')
//           .doc(markerId)
//           .update({
//         'files': updatedFiles,
//       });
//
//       // تحديث واجهة المستخدم
//       setState(() {
//         _selectedMarkerDetails?['files'] = updatedFiles;
//       });
//
//       // إشعار نجاح
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('تم حذف الملف بنجاح!')),
//       );
//     } catch (e) {
//       // إشعار في حالة حدوث خطأ
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('حدث خطأ أثناء حذف الملف: $e')),
//       );
//     }
//   }
//
//   // delete Note
//   Future<void> _deleteNote(int index) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null || _selectedMarkerDetails == null) return;
//
//       final markerId = _selectedMarkerDetails!['markerId'];
//
//       // حذف الملاحظة من القائمة المحلية
//       setState(() {
//         _notes.removeAt(index);
//       });
//
//       // تحديث قائمة الملاحظات في Firestore
//       await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('markers')
//           .doc(markerId)
//           .update({
//         'additionalNotes': _notes, // تحديث القائمة بعد الحذف
//       });
//
//       // إشعار نجاح
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('تم حذف الملاحظة بنجاح!')),
//       );
//     } catch (e) {
//       // إشعار بخطأ
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('حدث خطأ أثناء حذف الملاحظة: $e')),
//       );
//     }
//   }
//
//   // download File
//   Future<void> _downloadFile(String fileUrl) async {
//     if (await canLaunch(fileUrl)) {
//       await launch(fileUrl);
//     } else {
//       throw 'Could not launch $fileUrl';
//     }
//   }
//
//   // clear Markers
//   Future<void> _clearMarkers() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     await _firestore
//         .collection('users')
//         .doc(user.uid)
//         .collection('markers')
//         .get()
//         .then((snapshot) {
//       for (var doc in snapshot.docs) {
//         doc.reference.delete();
//       }
//     });
//
//     setState(() {
//       _markers.clear();
//       _selectedMarkerDetails = null;
//       _notes.clear();
//     });
//   }
//
//
//   Future<void> _addMarkerWithCoordinates() async {
//     TextEditingController _nameController = TextEditingController();
//     TextEditingController _latitudeController = TextEditingController();
//     TextEditingController _longitudeController = TextEditingController();
//     TextEditingController _noteController = TextEditingController();
//     String? _selectedType;
//     bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
//
//     // عرض حوار إدخال البيانات
//     final result = await showDialog<List<dynamic>>(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return Stack(
//           children: [
//             Align(
//               alignment:
//               // Alignment.topRight,
//               isArabic ? Alignment.topLeft : Alignment.topRight,
//               child: Padding(
//                 padding: const EdgeInsets.only(top: 50, right: 16), // مسافة من الأعلى واليمين
//                 child: Material(
//                   color: Colors.transparent,
//                   child: Container(
//                     width: 350, // عرض النموذج
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(15),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 10,
//                           offset: Offset(0, 5),
//                         ),
//                       ],
//                     ),
//                     child: SingleChildScrollView(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'إضافة موقع جديد',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blueGrey,
//                             ),
//                           ),
//                           SizedBox(height: 15),
//                           TextField(
//                             controller: _nameController,
//                             decoration: InputDecoration(
//                               labelText: 'اسم الموقع',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: 10),
//                           TextField(
//                             controller: _latitudeController,
//                             keyboardType: TextInputType.number,
//                             decoration: InputDecoration(
//                               labelText: 'خط العرض (Latitude)',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: 10),
//                           TextField(
//                             controller: _longitudeController,
//                             keyboardType: TextInputType.number,
//                             decoration: InputDecoration(
//                               labelText: 'خط الطول (Longitude)',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: 10),
//                           DropdownButtonFormField<String>(
//                             value: _selectedType,
//                             decoration: InputDecoration(
//                               labelText: 'نوع الموقع',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             items: _iconTypes.entries.map((entry) {
//                               return DropdownMenuItem<String>(
//                                 value: entry.key,
//                                 child: Row(
//                                   children: [
//                                     Image.asset(
//                                       entry.value,
//                                       width: 24,
//                                       height: 24,
//                                     ),
//                                     SizedBox(width: 10),
//                                     Text(entry.key),
//                                   ],
//                                 ),
//                               );
//                             }).toList(),
//                             onChanged: (value) => _selectedType = value,
//                           ),
//                           SizedBox(height: 10),
//                           TextField(
//                             controller: _noteController,
//                             decoration: InputDecoration(
//                               labelText: 'ملاحظة الموقع',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: 20),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(''),
//                               TextButton(
//                                 onPressed: () => Navigator.of(context).pop(),
//                                 child: Text(
//                                   'إلغاء',
//                                   style: TextStyle(color: Colors.red),
//                                 ),
//                               ),
//                               ElevatedButton(
//                                 onPressed: () {
//                                   if (_nameController.text.trim().isEmpty ||
//                                       _latitudeController.text.trim().isEmpty ||
//                                       _longitudeController.text.trim().isEmpty ||
//                                       _selectedType == null) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(
//                                         content:
//                                         Text('الرجاء إدخال جميع البيانات'),
//                                       ),
//                                     );
//                                   } else {
//                                     Navigator.of(context).pop([
//                                       _nameController.text.trim(),
//                                       double.tryParse(
//                                           _latitudeController.text.trim()),
//                                       double.tryParse(
//                                           _longitudeController.text.trim()),
//                                       _selectedType,
//                                       _noteController.text.trim(),
//                                     ]);
//                                   }
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blueGrey,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                                 child: Text('إضافة'),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (result == null || result.length < 5 || result[1] == null || result[2] == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('تعذر إضافة العلامة. تأكد من البيانات المدخلة.')),
//       );
//       return;
//     }
//
//     final String name = result[0];
//     final double latitude = result[1];
//     final double longitude = result[2];
//     final String type = result[3];
//     final String note = result[4];
//     final String imagePath = _iconTypes[type]!;
//
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     final markerId = MarkerId(DateTime.now().toString());
//
//     final marker = Marker(
//       markerId: markerId,
//       position: LatLng(latitude, longitude),
//       infoWindow: InfoWindow(
//         title: name,
//         snippet: 'النوع: $type\nالموقع: ($latitude, $longitude)',
//       ),
//       icon: BitmapDescriptor.defaultMarker,
//       onTap: () => _fetchMarkerDetails(markerId.value),
//     );
//
//     setState(() {
//       _markers.add(marker);
//     });
//
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('markers')
//         .doc(markerId.value)
//         .set({
//       'name': name,
//       'latitude': latitude,
//       'longitude': longitude,
//       'type': type,
//       'note': note,
//       'image': imagePath,
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('تمت إضافة العلامة بنجاح!')),
//     );
//   }
//
//
//   Future<void> _fetchMarkerDetails(String markerId) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     final doc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('markers')
//         .doc(markerId)
//         .get();
//
//     if (doc.exists) {
//       final data = doc.data();
//
//       setState(() {
//         _selectedMarkerDetails = data;
//       });
//
//     }
//   }
//
//
//
//
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Map Gaza',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         elevation: 15,
//         backgroundColor: Colors.teal,
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
//               child:
//               Tooltip(message: 'اضافة موقع',
//                 child: IconButton(
//                   icon: Icon(Icons.location_on),
//                   onPressed: () => _addMarkerWithCoordinates(),
//                 ),
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
//               child:   Tooltip(message: 'حذف العلامات',
//                 child: IconButton(
//                   icon: Icon(Icons.delete),
//                   onPressed: () => _clearMarkers(),
//                 ),
//               ),
//
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
//               child:   Tooltip(message: 'الرجوع',
//                 child: IconButton(
//                   onPressed: () {
//                     Navigator.pushReplacementNamed(context, '/home');
//                   },
//                   icon: const Icon(Icons.arrow_forward_ios_outlined),
//                 ),
//               ),
//
//             ),
//           ),
//         ],
//       ),
//       body:
//       LayoutBuilder(
//         builder: (context, constraints) {
//           bool isMobile = !kIsWeb && constraints.maxWidth < 600;
//
//           return Column(
//             children: [
//               if (isMobile)
//                 Container(
//                   width: 200,
//                   height: 200,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.5),
//                         spreadRadius: 5,
//                         blurRadius: 10,
//                         offset: const Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(20),
//                     child: GoogleMap(
//                       mapType: MapType.hybrid,
//                       initialCameraPosition: CameraPosition(
//                         target: _initialPosition,
//                         zoom: 16.0,
//                       ),
//                       markers: _markers,
//                       onMapCreated: (GoogleMapController controller) {
//                         _controller.complete(controller);
//                       },
//                       onTap: (LatLng position) {
//                         _addMarker(position);
//                       },
//                     ),
//                   ),
//                 ),
//
//               Expanded(
//                 child: isMobile
//                     ? _buildMarkerDetails()
//                     : Row(
//                   children: [
//                     _buildMap(),
//                     Expanded(child: _buildMarkerDetails()),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//   Widget _buildMap() {
//     return Container(
//       width: 1100,
//       height: 700,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.5),
//             spreadRadius: 5,
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: GoogleMap(
//           mapType: MapType.hybrid,
//           initialCameraPosition: CameraPosition(
//             target: _initialPosition,
//             zoom: 16.0,
//           ),
//           markers: _markers,
//           onMapCreated: (GoogleMapController controller) {
//             _controller.complete(controller);
//           },
//           onTap: (LatLng position) {
//             _addMarker(position);
//           },
//         ),
//       ),
//     );
//   }
//
//   /// دالة بناء تفاصيل العلامة
//   Widget _buildMarkerDetails() {
//     return _selectedMarkerDetails == null
//         ? const Center(
//       child: Text(
//         'اضغط على علامة لرؤية التفاصيل.',
//         style: TextStyle(fontSize: 16),
//       ),
//     )
//         : Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: SingleChildScrollView(
//         // scrollDirection: Axis.horizontal,
//         child: SingleChildScrollView(
//           // scrollDirection: Axis.vertical,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'تفاصيل العلامة:',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 10),
//               if (_selectedMarkerDetails?['image'] != null)
//                 Image.asset(
//                   _selectedMarkerDetails!['image'],
//                   height: 100,
//                   width: 100,
//                 ),
//               Text('النوع: ${_selectedMarkerDetails?['type'] ?? ''}'),
//               Text('الاسم: ${_selectedMarkerDetails?['note'] ?? ''}'),
//               Text(
//                   'الموقع: (${_selectedMarkerDetails?['latitude']}, ${_selectedMarkerDetails?['longitude']})'),
//               const SizedBox(height: 20),
//               const Text(
//                 'الملفات المرفقة:',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               _buildFileList(),
//               SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: _uploadFile,
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor: Colors.blueAccent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10.0),
//                   ),
//                 ),
//                 child: Text('رفع الملف'),
//               ),
//               SizedBox(height: 10),
//
//               SizedBox(
//                 height: 200,
//                 child: ListView.builder(
//                   itemCount: _notes.length,
//                   shrinkWrap: true,
//                   physics: BouncingScrollPhysics(),
//                   itemBuilder: (context, index) {
//                     return ListTile(
//                       title: Text(_notes[index]),
//                       leading: Icon(Icons.star, color: Colors.blue),
//                       trailing:  Tooltip(message: 'حذف',
//                         child: IconButton(
//                           icon: Icon(Icons.delete, color: Colors.red),
//                           onPressed: () {
//                             _deleteNote(index);
//                           },
//                         ),
//                       ),
//
//                     );
//                   },
//                 ),
//               ),
//
//               SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: _addNote,
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor: Colors.blueAccent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10.0),
//                   ),
//                 ),
//                 child: Text('إضافة ملاحظة'),
//               ),
//             ],
//           ),
//         ),
//       ),
//   // Row(children: [
//       //   // the map
//       //   Padding(
//       //     padding: const EdgeInsets.only(
//       //         top: 15.0, left: 15.0, right: 15.0, bottom: 20.0),
//       //     child: Container(
//       //       width: width,
//       //       height: height,
//       //       decoration: BoxDecoration(
//       //         color: Colors.white,
//       //         borderRadius: BorderRadius.circular(20),
//       //         boxShadow: [
//       //           BoxShadow(
//       //             color: Colors.grey.withOpacity(0.5),
//       //             spreadRadius: 5,
//       //             blurRadius: 10,
//       //             offset: const Offset(0, 3),
//       //           ),
//       //         ],
//       //       ),
//       //       child:
//       //       ClipRRect(
//       //         borderRadius: BorderRadius.circular(20),
//       //         child: GoogleMap(
//       //           mapType: MapType.normal,
//       //           initialCameraPosition: CameraPosition(
//       //             target: _initialPosition,
//       //             zoom: 16.0,
//       //           ),
//       //           markers: _markers,
//       //           onMapCreated: (GoogleMapController controller) {
//       //             _controller.complete(controller);
//       //           },
//       //           onTap: (LatLng position) {
//       //             _addMarker(position);
//       //           },
//       //         ),
//       //       ),
//       //     ),
//       //   ),
//       //   // details
//       //   // Expanded(
//       //   //   child: _selectedMarkerDetails == null
//       //   //       ? const Center(
//       //   //           child: Text(
//       //   //             'اضغط على علامة لرؤية التفاصيل.',
//       //   //             style: TextStyle(fontSize: 16),
//       //   //           ),
//       //   //         )
//       //   //       : Padding(
//       //   //           padding: const EdgeInsets.all(16.0),
//       //   //           child: Column(
//       //   //               crossAxisAlignment: CrossAxisAlignment.start,
//       //   //               children: [
//       //   //                 const Text(
//       //   //                   'تفاصيل العلامة:',
//       //   //                   style: TextStyle(
//       //   //                       fontSize: 20, fontWeight: FontWeight.bold),
//       //   //                 ),
//       //   //                 SizedBox(height: 10),
//       //   //                 if (_selectedMarkerDetails?['image'] != null)
//       //   //                   Image.asset(
//       //   //                     _selectedMarkerDetails!['image'],
//       //   //                     height: 100,
//       //   //                     width: 100,
//       //   //                   ),
//       //   //                 Text('النوع: ${_selectedMarkerDetails?['type'] ?? ''}'),
//       //   //                 Text('الاسم: ${_selectedMarkerDetails?['note'] ?? ''}'),
//       //   //                 Text(
//       //   //                     'الموقع: (${_selectedMarkerDetails?['latitude']}, ${_selectedMarkerDetails?['longitude']})'),
//       //   //                 const SizedBox(height: 20),
//       //   //                 const Text(
//       //   //                   'الملفات المرفقة:',
//       //   //                   style: TextStyle(
//       //   //                       fontSize: 18, fontWeight: FontWeight.bold),
//       //   //                 ),
//       //   //                 Expanded(child: _buildFileList()),
//       //   //                 SizedBox(height: 10),
//       //   //
//       //   //
//       //   //                 ElevatedButton(
//       //   //                   onPressed: _uploadFile,
//       //   //                   style: ElevatedButton.styleFrom(
//       //   //                     foregroundColor: Colors.white,
//       //   //                     backgroundColor: Colors.blueAccent,
//       //   //                     shape: RoundedRectangleBorder(
//       //   //                       borderRadius: BorderRadius.circular(10.0),
//       //   //                     ),
//       //   //                   ),
//       //   //                   child: Text('رفع الملف'),
//       //   //                 ),
//       //   //                 Expanded(
//       //   //                   child: ListView.builder(
//       //   //                     itemCount: _notes.length,
//       //   //                     itemBuilder: (context, index) {
//       //   //                       return ListTile(
//       //   //                         title: Text(_notes[index]),
//       //   //                         leading: Icon(Icons.star, color: Colors.blue),
//       //   //                         trailing: IconButton(
//       //   //                           icon: Icon(Icons.delete, color: Colors.red),
//       //   //
//       //   //                           onPressed: () {
//       //   //                             _deleteNote(
//       //   //                                 index);
//       //   //                           },
//       //   //                         ),
//       //   //                       );
//       //   //                     },
//       //   //                   ),
//       //   //                 ),
//       //   //                 SizedBox(height: 10),
//       //   //                 ElevatedButton(
//       //   //                   onPressed: _addNote,
//       //   //                   style: ElevatedButton.styleFrom(
//       //   //                     foregroundColor: Colors.white,
//       //   //                     backgroundColor: Colors.blueAccent,
//       //   //                     shape: RoundedRectangleBorder(
//       //   //                       borderRadius: BorderRadius.circular(10.0),
//       //   //                     ),
//       //   //                   ),
//       //   //                   child: Text('إضافة ملاحظة'),
//       //   //                 ),
//       //   //               ]),
//       //   //         ),
//       //   // )
//       //   Expanded(
//       //     child: _selectedMarkerDetails == null
//       //         ? const Center(
//       //       child: Text(
//       //         'اضغط على علامة لرؤية التفاصيل.',
//       //         style: TextStyle(fontSize: 16),
//       //       ),
//       //     )
//       //         : Padding(
//       //       padding: const EdgeInsets.all(16.0),
//       //       child: SingleChildScrollView( // ✅ إضافة السكرول هنا
//       //         child: Column(
//       //           crossAxisAlignment: CrossAxisAlignment.start,
//       //           children: [
//       //             const Text(
//       //               'تفاصيل العلامة:',
//       //               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//       //             ),
//       //             SizedBox(height: 10),
//       //             if (_selectedMarkerDetails?['image'] != null)
//       //               Image.asset(
//       //                 _selectedMarkerDetails!['image'],
//       //                 height: 100,
//       //                 width: 100,
//       //               ),
//       //             Text('النوع: ${_selectedMarkerDetails?['type'] ?? ''}'),
//       //             Text('الاسم: ${_selectedMarkerDetails?['note'] ?? ''}'),
//       //             Text(
//       //                 'الموقع: (${_selectedMarkerDetails?['latitude']}, ${_selectedMarkerDetails?['longitude']})'),
//       //             const SizedBox(height: 20),
//       //             const Text(
//       //               'الملفات المرفقة:',
//       //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       //             ),
//       //             _buildFileList(),
//       //             SizedBox(height: 10),
//       //             ElevatedButton(
//       //               onPressed: _uploadFile,
//       //               style: ElevatedButton.styleFrom(
//       //                 foregroundColor: Colors.white,
//       //                 backgroundColor: Colors.blueAccent,
//       //                 shape: RoundedRectangleBorder(
//       //                   borderRadius: BorderRadius.circular(10.0),
//       //                 ),
//       //               ),
//       //               child: Text('رفع الملف'),
//       //             ),
//       //             SizedBox(height: 10),
//       //
//       //             // ✅ التمرير فقط داخل قائمة الملاحظات
//       //             SizedBox(
//       //               height: 200, // تحديد ارتفاع ليسمح بالتمرير داخل ListView
//       //               child: ListView.builder(
//       //                 itemCount: _notes.length,
//       //                 shrinkWrap: true, // ✅ يمنع مشكلة التمرير
//       //                 physics: BouncingScrollPhysics(), // ✅ تمرير ناعم
//       //                 itemBuilder: (context, index) {
//       //                   return ListTile(
//       //                     title: Text(_notes[index]),
//       //                     leading: Icon(Icons.star, color: Colors.blue),
//       //                     trailing: IconButton(
//       //                       icon: Icon(Icons.delete, color: Colors.red),
//       //                       onPressed: () {
//       //                         _deleteNote(index);
//       //                       },
//       //                     ),
//       //                   );
//       //                 },
//       //               ),
//       //             ),
//       //
//       //             SizedBox(height: 10),
//       //             ElevatedButton(
//       //               onPressed: _addNote,
//       //               style: ElevatedButton.styleFrom(
//       //                 foregroundColor: Colors.white,
//       //                 backgroundColor: Colors.blueAccent,
//       //                 shape: RoundedRectangleBorder(
//       //                   borderRadius: BorderRadius.circular(10.0),
//       //                 ),
//       //               ),
//       //               child: Text('إضافة ملاحظة'),
//       //             ),
//       //           ],
//       //         ),
//       //       ),
//       //     ),
//       //   )
//       //
//       // ]),
//       // show location me
//       // floatingActionButton: FloatingActionButton(
//       //   onPressed: () async {
//       //     final GoogleMapController controller = await _controller.future;
//       //     controller.animateCamera(
//       //       CameraUpdate.newLatLngZoom(_initialPosition, 14),
//       //     );
//       //   },
//       //   child: Icon(Icons.my_location),
//       //   backgroundColor: Colors.teal,
//       // ),
//     );
//   }
// }
//
//
//
//
//
//
//




import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled4/components/context-extenssion.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  LatLng _initialPosition = LatLng(31.383312, 34.299018);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _selectedMarkerDetails;
  List<String> _notes = [];

  final Map<String, String> _iconTypes = {
    "مزرعة": "assets/icons/farm.jpeg",
    "مخيم": "assets/icons/camp.jpeg",
    "مركز طبي": "assets/icons/medical.jpeg",
    "مؤسسة": "assets/icons/institution.jpeg",
    "مدرسة": "assets/icons/school.jpeg",
    "مجمع سكني": "assets/icons/residential.jpeg",
    "خط مياه": "assets/icons/water.jpeg",
  };

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }
  Future<Map<String, String?>?> _showTypeAndNoteDialog() async {
    TextEditingController _noteController = TextEditingController();
    String? selectedType;
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return await showDialog<Map<String, String?>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Align(
              alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: EdgeInsets.only(
                    top: 200,
                    left: isArabic ? 0 : 1000,
                    right: isArabic ? 1000 : 0,
                  ),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 5,
                        offset: Offset(5, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'إضافة علامة' : 'Add Marker',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      DropdownButton<String>(
                        value: selectedType,
                        hint: Text(isArabic ? 'اختر نوع العلامة' : 'Select Marker Type'),
                        isExpanded: true,
                        items: _iconTypes.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Row(
                              children: [
                                Image.asset(entry.value, width: 40, height: 40),
                                SizedBox(width: 10),
                                Text(entry.key),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'أدخل الملاحظة هنا' : 'Enter note here',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (selectedType != null) {
                                Navigator.of(context).pop({
                                  'type': selectedType,
                                  'note': _noteController.text.trim(),
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(isArabic ? 'حفظ' : 'Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  Future<void> _loadMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("🚨 المستخدم غير مسجل الدخول.");
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('markers')
          .get();

      if (snapshot.docs.isEmpty) {
        print("ℹ️ لا يوجد أي علامات محفوظة.");
        return;
      }

      List<Marker> tempMarkers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (!data.containsKey('latitude') || !data.containsKey('longitude')) {
          print("🚨 المستند ${doc.id} مفقود بيانات الموقع.");
          continue;
        }

        double? latitude = (data['latitude'] as num?)?.toDouble();
        double? longitude = (data['longitude'] as num?)?.toDouble();

        if (latitude == null || longitude == null) {
          print("⚠️ المستند ${doc.id} يحتوي على إحداثيات غير صالحة.");
          continue;
        }

        final markerId = doc.id;
        final marker = Marker(
          markerId: MarkerId(markerId),
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(
            title: data['type'] ?? "علامة",
            snippet: data['note'] ?? '',
          ),
          onTap: () => _showMarkerDetails(markerId),
        );

        tempMarkers.add(marker);
      }

      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.addAll(tempMarkers);
        });
      } else {
        print("⚠️ `setState()` تم استدعاؤه بعد `dispose()`.");
      }
    } catch (e) {
      print("❌ خطأ أثناء تحميل العلامات: $e");
    }
  }
  Future<void> _addMarker(LatLng position) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, String?>? result = await _showTypeAndNoteDialog();
    if (result == null || result['type'] == null) return;

    final String selectedType = result['type']!;
    final String? note = result['note'];

    final markerId = MarkerId(DateTime.now().toString());
    final marker = Marker(
      markerId: markerId,
      position: position,
      infoWindow: InfoWindow(title: selectedType, snippet: note),
      onTap: () => _showMarkerDetails(markerId.value),
    );

    setState(() {
      _markers.add(marker);
    });

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('markers')
        .doc(markerId.value)
        .set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'type': selectedType,
      'image': _iconTypes[selectedType],
      'note': note,
      'files': [],
      'additionalNotes': [],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  Future<void> _deleteNote(int index) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _selectedMarkerDetails == null) return;

      final markerId = _selectedMarkerDetails!['markerId'];

      // حذف الملاحظة من القائمة المحلية
      setState(() {
        _notes.removeAt(index);
      });

      // تحديث قائمة الملاحظات في Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('markers')
          .doc(markerId)
          .update({
        'additionalNotes': _notes, // تحديث القائمة بعد الحذف
      });

      // إشعار نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف الملاحظة بنجاح!')),
      );
    } catch (e) {
      // إشعار بخطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف الملاحظة: $e')),
      );
    }
  }
  Future<void> _addNote() async {
    if (_selectedMarkerDetails == null) return;

    TextEditingController _noteController = TextEditingController();

    String? newNote = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text('إضافة ملاحظة جديدة'),
          content: TextField(
            controller: _noteController,
            decoration: InputDecoration(hintText: 'أدخل الملاحظة هنا'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('إلغاء', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_noteController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('⚠️ لا يمكن ترك الملاحظة فارغة!')),
                  );
                } else {
                  Navigator.of(context).pop(_noteController.text.trim());
                }
              },
              child: Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (newNote == null || newNote.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final markerId = _selectedMarkerDetails!['markerId'];

    _notes.add(newNote);

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('markers')
        .doc(markerId)
        .update({
      'additionalNotes': _notes,
    });

    setState(() {});
  }
  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();

      if (result == null || _selectedMarkerDetails == null) {
        print("لم يتم اختيار أي ملف.");
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("المستخدم غير مسجل دخول.");
        return;
      }

      final markerId = _selectedMarkerDetails!['markerId'];
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;

      String fileName = result.files.single.name;
      String storagePath = 'users/${user.uid}/markers/$markerId/$fileName';
      Reference storageRef = storage.ref().child(storagePath);

      String downloadUrl = '';

      if (kIsWeb) {
        // 📌 **للوِب**: استخدم `bytes`
        Uint8List? fileBytes = result.files.single.bytes;
        if (fileBytes == null) {
          print("⚠️ لا يوجد بيانات في الملف.");
          return;
        }

        UploadTask uploadTask = storageRef.putData(fileBytes);
        TaskSnapshot snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else {
        // 📌 **لنظام Android/iOS**: استخدم `path`
        String? filePath = result.files.single.path;
        if (filePath == null) {
          print("⚠️ لا يوجد مسار للملف.");
          return;
        }

        File file = File(filePath);

        // ✅ **طلب إذن الوصول إلى الملفات على Android**
        if (Platform.isAndroid) {
          var status = await Permission.storage.request();
          if (status.isDenied) {
            print("🚫 تم رفض إذن الوصول إلى الملفات.");
            return;
          }
        }

        UploadTask uploadTask = storageRef.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      // ✅ تحديث Firestore بالرابط الجديد للملف
      DocumentReference markerDoc = firestore
          .collection('users')
          .doc(user.uid)
          .collection('markers')
          .doc(markerId);

      await markerDoc.update({
        'files': FieldValue.arrayUnion([downloadUrl]),
      });

      setState(() {
        _selectedMarkerDetails?['files'] =
        List<String>.from(_selectedMarkerDetails?['files'] ?? [])..add(downloadUrl);
      });

      print("✅ تم رفع الملف بنجاح: $downloadUrl");
    } catch (e) {
      print("❌ حدث خطأ أثناء رفع الملف: $e");
    }
  }
  Future<void> _showMarkerDetails(String markerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('markers')
        .doc(markerId)
        .get();

    if (doc.exists) {
      setState(() {
        _selectedMarkerDetails = doc.data();
        _selectedMarkerDetails?['markerId'] = markerId;
        _notes = List<String>.from(_selectedMarkerDetails?['additionalNotes'] ?? []);
      });
    }
  }
  Future<void> _deleteFile(String fileUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _selectedMarkerDetails == null) return;

      final markerId = _selectedMarkerDetails!['markerId'];

      // حذف الملف من Firebase Storage
      final storageRef = FirebaseStorage.instance.refFromURL(fileUrl);
      await storageRef.delete();

      // إزالة رابط الملف من Firestore
      final List<String> updatedFiles =
      List<String>.from(_selectedMarkerDetails?['files'] ?? []);
      updatedFiles.remove(fileUrl);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('markers')
          .doc(markerId)
          .update({
        'files': updatedFiles,
      });

      // تحديث واجهة المستخدم
      setState(() {
        _selectedMarkerDetails?['files'] = updatedFiles;
      });

      // إشعار نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف الملف بنجاح!')),
      );
    } catch (e) {
      // إشعار في حالة حدوث خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف الملف: $e')),
      );
    }
  }
  Future<void> _downloadFile(String fileUrl) async {
    if (await canLaunch(fileUrl)) {
      await launch(fileUrl);
    } else {
      throw 'لا يمكن فتح الرابط: $fileUrl';
    }
  }
  Widget _buildFileList() {
    final files = List<String>.from(_selectedMarkerDetails?['files'] ?? []);

    if (files.isEmpty) {
      return Text('لا توجد ملفات مرفقة.');
    }

    return ListView.builder(
      itemCount: files.length,
      shrinkWrap: true,
      physics: BouncingScrollPhysics(), // تحسين التمرير
      itemBuilder: (context, index) {
        final fileUrl = files[index];
        String fileName = Uri.decodeComponent(fileUrl.split('?').first.split('/').last);

        return ListTile(
          title: Text(fileName.split('/').last), // عرض اسم الملف فقط
          leading: Icon(Icons.file_present, color: Colors.green),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.download),
                onPressed: () {
                  _downloadFile(fileUrl); // استدعاء دالة التنزيل
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _deleteFile(fileUrl); // استدعاء دالة الحذف
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _addMarkerWithCoordinates() async {
    TextEditingController _nameController = TextEditingController();
    TextEditingController _latitudeController = TextEditingController();
    TextEditingController _longitudeController = TextEditingController();
    TextEditingController _noteController = TextEditingController();
    String? _selectedType;
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // عرض نافذة الإدخال بمحاذاة متغيرة حسب اللغة
    final result = await showDialog<List<dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Stack(
          children: [
            Align(
              alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight, // ✅ أقصى الشمال أو أقصى اليمين
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300, // عرض النافذة
                  height: 430, // طول النافذة
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArabic ? 'إضافة موقع جديد' : 'Add New Location',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'اسم الموقع' : 'Location Name',
                            prefixIcon: Icon(Icons.location_on, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _latitudeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Latitude (خط العرض)',
                            prefixIcon: Icon(Icons.map, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _longitudeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Longitude (خط الطول)',
                            prefixIcon: Icon(Icons.map_outlined, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'نوع الموقع' : 'Location Type',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _iconTypes.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Row(
                                children: [
                                  Image.asset(entry.value, width: 24, height: 24),
                                  const SizedBox(width: 10),
                                  Text(entry.key),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => _selectedType = value,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'ملاحظة الموقع' : 'Location Note',
                            prefixIcon: Icon(Icons.note, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                isArabic ? 'إلغاء' : 'Cancel',
                                style: TextStyle(color: Colors.red, fontSize: 16),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_nameController.text.trim().isEmpty ||
                                    _latitudeController.text.trim().isEmpty ||
                                    _longitudeController.text.trim().isEmpty ||
                                    _selectedType == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(isArabic ? 'الرجاء إدخال جميع البيانات' : 'Please enter all fields')),
                                  );
                                } else {
                                  Navigator.of(context).pop([
                                    _nameController.text.trim(),
                                    double.tryParse(_latitudeController.text.trim()),
                                    double.tryParse(_longitudeController.text.trim()),
                                    _selectedType,
                                    _noteController.text.trim(),
                                  ]);
                                }
                              },
                              icon: Icon(Icons.add, color: Colors.white),
                              label: Text(isArabic ? 'إضافة' : 'Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == null || result.length < 5 || result[1] == null || result[2] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'تعذر إضافة العلامة. تأكد من البيانات المدخلة.' : 'Failed to add marker. Please check input data.')),
      );
      return;
    }

    final String name = result[0];
    final double latitude = result[1];
    final double longitude = result[2];
    final String type = result[3];
    final String note = result[4];
    final String imagePath = _iconTypes[type]!;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final markerId = MarkerId(DateTime.now().toString());

    final marker = Marker(
      markerId: markerId,
      position: LatLng(latitude, longitude),
      infoWindow: InfoWindow(
        title: name,
        snippet: 'النوع: $type\nالموقع: ($latitude, $longitude)',
      ),
      icon: BitmapDescriptor.defaultMarker,
      onTap: () => _showMarkerDetails(markerId.value),
    );

    setState(() {
      _markers.add(marker);
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('markers')
        .doc(markerId.value)
        .set({
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'note': note,
      'image': imagePath,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isArabic ? 'تمت إضافة العلامة بنجاح!' : 'Marker added successfully!')),
    );
  }
  Future<void> _clearMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // حذف جميع العلامات من Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('markers')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      // حذف جميع العلامات من واجهة المستخدم
      setState(() {
        _markers.clear();
        _selectedMarkerDetails = null;
        _notes.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم مسح جميع العلامات بنجاح!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ حدث خطأ أثناء حذف العلامات: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = !kIsWeb && MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title:  Text(context.localizations.map_gaza, style: TextStyle(fontWeight: FontWeight.bold)),
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
              child:
              Tooltip(message: 'اضافة موقع',
                child: IconButton(
                  icon: Icon(Icons.location_on),
                  onPressed: () => _addMarkerWithCoordinates(),
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
              child:   Tooltip(message: 'حذف العلامات',
                child: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _clearMarkers(),
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
              child:   Tooltip(message: 'الرجوع',
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

        backgroundColor: Colors.teal,
      ),
      body: isMobile
          ? Column(
        children: [
          Expanded(child: _buildMap()), // ✅ عرض الخريطة فقط
          _buildMarkerDetails(), // ✅ إظهار التفاصيل أسفل الخريطة
        ],
      )
          : Row(
        children: [
          _buildMap(), // ✅ عرض الخريطة في النصف الأول
          Expanded(child: _buildMarkerDetails()), // ✅ عرض التفاصيل في النصف الثاني
        ],
      ),
    );
  }


  Widget _buildMap() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white, // لون الخلفية
        borderRadius: BorderRadius.circular(20), // زوايا دائرية
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // لون الظل
            blurRadius: 10, // حدة الظل
            spreadRadius: 5, // مدى انتشار الظل
            offset: Offset(0, 5), // موقع الظل
          ),
        ],
      ),
      child: Container(
        width: kIsWeb ? 1100 : double.infinity,
        height: kIsWeb ? 700 : 400,
        child: GoogleMap(
          mapType: MapType.hybrid,
          initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 16.0),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          onTap: (LatLng position) {
            _addMarker(position);
          },
        ),
      ),
    );

  }


  Widget _buildMarkerDetails() {
    return _selectedMarkerDetails == null
        ? const Center(child: Text(
        'اضغط على علامة لرؤية التفاصيل.', style: TextStyle(fontSize: 16)))
        : Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تفاصيل العلامة:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (_selectedMarkerDetails?['image'] != null)
              Image.asset(
                  _selectedMarkerDetails!['image'], height: 100, width: 100),
            Text('النوع: ${_selectedMarkerDetails?['type'] ?? ''}'),
            Text('الملاحظة: ${_selectedMarkerDetails?['note'] ?? ''}'),
            const SizedBox(height: 20),
            const Text('الملفات المرفقة:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildFileList(),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _uploadFile,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text('رفع الملف'),
            ),
            SizedBox(height: 10),

            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _notes.length,
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_notes[index]),
                    leading: Icon(Icons.star, color: Colors.blue),
                    trailing: Tooltip(message: 'حذف',
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteNote(index);
                        },
                      ),
                    ),

                  );
                },
              ),
            ),

            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addNote,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text('إضافة ملاحظة'),
            ),
          ],
        ),
  ),
    );
  }

}
