import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../components/my_button.dart';
import '../../components/my_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  // حوار لتغيير كلمة المرور


  Future<void> showChangePasswordDialog(BuildContext context) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final emailController = TextEditingController(); // إضافة حقل البريد الإلكتروني

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // يمنع إغلاق الحوار بالنقر خارج المربع
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // إدخال البريد الإلكتروني
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(hintText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                // إدخال كلمة المرور القديمة
                TextField(
                  controller: oldPasswordController,
                  decoration: const InputDecoration(hintText: 'Old Password'),
                  obscureText: true, // إخفاء النص المدخل
                ),
                // إدخال كلمة المرور الجديدة
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(hintText: 'New Password'),
                  obscureText: true, // إخفاء النص المدخل
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // إغلاق الحوار
              },
            ),
            TextButton(
              child: const Text('Change'),
              onPressed: () async {
                final email = emailController.text.trim();
                final oldPassword = oldPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();

                if (email.isEmpty || oldPassword.isEmpty || newPassword.isEmpty) {
                  _showErrorDialog(context, 'All fields are required.');
                  return;
                }

                await changePassword(context, email, oldPassword, newPassword);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> changePassword(BuildContext context, String email, String oldPassword, String newPassword) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // إعادة التحقق من هوية المستخدم
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: oldPassword,
        );

        await user.reauthenticateWithCredential(credential);

        // تحديث كلمة المرور
        await user.updatePassword(newPassword);

        // إظهار رسالة نجاح
        Navigator.of(context).pop();
        _showSuccessDialog(context, 'Password changed successfully.');
      }
    } catch (e) {
      // التعامل مع الأخطاء وإظهار رسالة توضيحية
      _showErrorDialog(context, 'Failed to change password: ${e.toString()}');
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void listenToUserChanges() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data();
          bool? isAdmin = data?['isAdmin'];

          // Update the lastModified field if isAdmin changes
          if (isAdmin != null) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              // 'lastModified': DateTime.now(),
            });
          }
        }
      });
    }
  }


  void signInUser(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Check if the document already exists
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // If the user document does not exist, create it with isAdmin as false
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': userCredential.user!.email,
          'userId': userCredential.user!.uid,
          'isAdmin': false,
          'lastLogin': DateTime.now(),
        });
      } else {
        // Update lastLogin for existing users
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': DateTime.now(),
        });
      }

      // Listen to changes in the user's document
      listenToUserChanges();

      if (userDoc.exists) {
        bool isAdmin = userDoc['isAdmin'] ?? false;
        if (isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to sign in';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided.';
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(errorMessage),
          );
        },
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
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

    child: SingleChildScrollView(
    physics: BouncingScrollPhysics(),
    child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'PARC',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 50),

                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'الاغاثة الزراعية الفلسطينية',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),


                    const Image(
                      width: 200,
                      height: 100,
                      image: AssetImage('assets/image/شعار مفرغ.png'),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: 500,
                      child: MyTextField(
                        controller: usernameController,
                        hintText: 'Username',
                        obscureText: false,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 500,
                      child: MyTextField(
                        controller: passwordController,
                        hintText: 'Password',
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 35),
                    isLoading
                        ? const CircularProgressIndicator()
                        :   Tooltip(message: 'تسجيل الدخول',
                      child:  MyButton(
                        onTap: () => signInUser(context),
                      ),
                    ),

                    const SizedBox(height: 30),
                    Container(
                      color: Colors.white.withOpacity(0.5),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                thickness: 0.5,
                                color: Colors.grey[400],
                              ),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(
                                'Or continue with',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                thickness: 0.5,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Tooltip(message: 'تغير كلمة السر',
                      child:     ElevatedButton(
                        onPressed: () {
                          showChangePasswordDialog(context);
                        },
                        child: Text(
                          'Change Password',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/my_cv_screen');
                      },
                      child: Text(
                        'Mohammed Balawi',
                        style: TextStyle(color: Colors.grey),
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




