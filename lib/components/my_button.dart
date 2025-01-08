import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;

  const MyButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: Colors.yellow[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            "Login in",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // دالة لتسجيل الدخول
  Future<void> loginUser() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      print("Please enter valid credentials.");
      return;
    }

    // هنا يمكن استخدام Firebase أو أي خدمة أخرى لتسجيل الدخول
    print("Logging in with email: $email and password: $password");

    // تنفيذ عملية تسجيل الدخول
    // يمكنك إضافة الكود الخاص بتسجيل الدخول هنا مثل Firebase Authentication أو أي آلية أخرى.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Screen"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (value) {
                  loginUser(); // تسجيل الدخول عند الضغط على Enter
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onSubmitted: (value) {
                  loginUser(); // تسجيل الدخول عند الضغط على Enter
                },
              ),
              const SizedBox(height: 20),
              MyButton(onTap: loginUser), // عند الضغط على الزر يتم تنفيذ عملية تسجيل الدخول
            ],
          ),
        ),
      ),
    );
  }
}

