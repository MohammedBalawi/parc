

import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled4/components/context-extenssion.dart';

class NameForm extends StatefulWidget {
  const NameForm({super.key});

  @override
  _NameFormState createState() => _NameFormState();
}

class _NameFormState extends State<NameForm> {
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _thirdNameController = TextEditingController();
  final _fourNameController = TextEditingController();
  final _fiveNameController = TextEditingController();
  final _coordinatesController_1 = TextEditingController();
  final _delegateController_1 = TextEditingController();
  final _coordinatesController_2 = TextEditingController();
  final _delegateController_2 = TextEditingController();

  List<String> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _showNames() async {
    if (_inputsAreEmpty()) {
      _showErrorMessage('Please fill all fields');
      return;
    }

    final date = DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now());
    final entry =
        '${_firstNameController.text}-${_secondNameController.text}-${_thirdNameController.text}-${_fourNameController.text}-${_fiveNameController.text}-${_coordinatesController_1.text}-${_delegateController_1.text}-${_coordinatesController_2.text}-${_delegateController_2.text}-$date';

    if (_entries.contains(entry)) {
      _showErrorMessage('Duplicate entry');
      return;
    }

    setState(() {
      _entries.insert(0, entry);
    });

    await _saveEntries();
  }

  void _editEntry(int index) async {
    final parts = _entries[index].split('-');
    if (parts.length < 10) return;

    _firstNameController.text = parts[0];
    _secondNameController.text = parts[1];
    _thirdNameController.text = parts[2];
    _fourNameController.text = parts[3];
    _fiveNameController.text = parts[4];
    _coordinatesController_1.text = parts[5];
    _delegateController_1.text = parts[6];
    _coordinatesController_2.text = parts[7];
    _delegateController_2.text = parts[8];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_firstNameController, 'Quantity Received'),
              _buildTextField(_secondNameController, 'Number of Recipients'),
              _buildTextField(_thirdNameController, 'Product Received'),
              _buildRowTextField(_fourNameController, _coordinatesController_1,
                  _delegateController_1, 'Camp 1', 'Coordinates', 'Admin'),
              _buildRowTextField(_fiveNameController, _coordinatesController_2,
                  _delegateController_2, 'Camp 2', 'Coordinates', 'Admin'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final date =
                  DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now());
              final updatedEntry =
                  '${_firstNameController.text}-${_secondNameController.text}-${_thirdNameController.text}-${_fourNameController.text}-${_fiveNameController.text}-${_coordinatesController_1.text}-${_delegateController_1.text}-${_coordinatesController_2.text}-${_delegateController_2.text}-$date';

              setState(() {
                _entries[index] = updatedEntry;
              });

              _saveEntries();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _sendToFirebase(String entry) async {
    final parts = entry.split('-');
    if (parts.length < 10) {
      _showErrorMessage('Invalid entry format for Firebase');
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    String? email = user?.email;

    if (email == null) {
      _showErrorMessage('User not logged in');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFirestore.instance.collection('names').add({
        'firstName': parts[0],
        'secondName': parts[1],
        'thirdName': parts[2],
        'camp1': parts[3],
        'coordinates1': parts[5],
        'admin1': parts[6],
        'camp2': parts[4],
        'coordinates2': parts[7],
        'admin2': parts[8],
        'date': parts[9],
        'senderEmail': email,
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data sent to Firebase successfully')),
      );
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorMessage('Failed to send data: $e');
    }
  }

  void _deleteEntry(int index) async {
    setState(() {
      _entries.removeAt(index);
    });
    await _saveEntries();
  }

  bool _inputsAreEmpty() {
    return _firstNameController.text.isEmpty ||
        _secondNameController.text.isEmpty ||
        _thirdNameController.text.isEmpty ||
        _fourNameController.text.isEmpty ||
        _fiveNameController.text.isEmpty;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _entries = prefs.getStringList('entries') ?? [];
    });
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('entries', _entries);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text(
          context.localizations.invoice,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
      ),
      body: SingleChildScrollView(
        child: Container(
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(_firstNameController, context.localizations.quantity_received),
                    _buildTextField(
                        _secondNameController, context.localizations.number_of_recipients),
                    _buildTextField(_thirdNameController, context.localizations.product_received),
                    _buildRowTextField(
                        _fourNameController,
                        _coordinatesController_1,
                        _delegateController_1,
                        context.localizations.camp_1,
                        context.localizations.coordinates_1,
                        context.localizations.admin_1),
                    _buildRowTextField(
                        _fiveNameController,
                        _coordinatesController_2,
                        _delegateController_2,
                        context.localizations.camp_2,
                        context.localizations.coordinates_2,
                        context.localizations.admin_2),
                    const SizedBox(height: 20),
                    _buildButton(context.localizations.ok, _showNames),
                    const SizedBox(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        return _buildListItem(index);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildRowTextField(
      TextEditingController campController,
      TextEditingController coordinatesController,
      TextEditingController delegateController,
      String campLabel,
      String coordinatesLabel,
      String delegateLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: campController,
              decoration: InputDecoration(
                labelText: campLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              controller: coordinatesController,
              decoration: InputDecoration(
                labelText: coordinatesLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              controller: delegateController,
              decoration: InputDecoration(
                labelText: delegateLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontSize: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  Widget _buildListItem(int index) {
    final parts = _entries[index].split('-');
    if (parts.length < 10) {
      return const Text('Invalid entry');
    }

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${context.localizations.quantity_received} : ${parts[0]}'),
            Text('${context.localizations.number_of_recipients}: ${parts[1]}'),
            Text('${context.localizations.product_received} : ${parts[2]}'),
            Row(
              children: [
                Expanded(child: Text('${context.localizations.camp_1} : ${parts[3]}')),
                Expanded(child: Text('${context.localizations.coordinates_1} : ${parts[5]}')),
                Expanded(child: Text('${context.localizations.admin_1} : ${parts[6]}')),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('${context.localizations.camp_2}: ${parts[4]}')),
                Expanded(child: Text('${context.localizations.coordinates_2} : ${parts[7]}')),
                Expanded(child: Text('${context.localizations.admin_2} : ${parts[8]}')),
              ],
            ),
            Text('${context.localizations.date} : ${parts[9]}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _editEntry(index),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child:Text(context.localizations.edit),
                ),
                ElevatedButton(
                  onPressed: () => _sendToFirebase(_entries[index]),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  child:  Text(context.localizations.send),
                ),
                ElevatedButton(
                  onPressed: () => _deleteEntry(index),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child:  Text(context.localizations.deleted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
