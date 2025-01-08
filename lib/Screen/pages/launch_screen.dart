import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  bool isLoading = true; // متغير للتحكم في مؤشر التحميل

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _navigateTo('/login'); // المستخدم غير مسجل
        return;
      }

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!snapshot.exists) {
        _navigateTo('/login'); // إذا لم تكن هناك بيانات للمستخدم
        return;
      }

      bool isAdmin = snapshot.get('isAdmin') ?? false;
      _navigateTo(isAdmin ? '/admin' : '/home'); // التوجيه بناءً على الصلاحية
    } catch (error) {
      print("❌ Error fetching user data: $error");
      _navigateTo('/login'); // في حال حدوث خطأ
    }
  }

  void _navigateTo(String route) {
    if (!mounted) return;

    setState(() {
      isLoading = false; // إيقاف مؤشر التحميل
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacementNamed(context, route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.yellow.shade300,
              Colors.yellow.shade700,
            ],
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'PARC',
          style: TextStyle(
            fontFamily: 'Arial',
            fontSize: 100,
            color: Colors.white,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}
