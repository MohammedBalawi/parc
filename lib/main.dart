import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'Screen/Chat/chat_screen.dart';
import 'Screen/Files/search_screen.dart';
import 'Screen/Files/send_screen.dart';
import 'Screen/Files/upload_screen.dart';
import 'Screen/Favorites/favorites_screen.dart';
import 'Screen/Invoice/invoice_screen.dart';
import 'Screen/map/map_screen.dart';
import 'Screen/pages/admin_screen.dart';
import 'Screen/pages/home_screen.dart';
import 'Screen/pages/launch_screen.dart';
import 'Screen/pages/login_screen.dart';
import 'Screen/Chat/privet_chat_screen.dart';
import 'Screen/Profiles/profile_screen.dart';
import 'Screen/Show/user.dart';
import 'components/language_provider.dart';
import 'components/shared.dart';
import 'cv/my_cv_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SharedPrefController().initPreferences();
  requestPermissions();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  BindingBase.debugZoneErrorsAreFatal = true;


  runApp(
    MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ChatProvider()),
      ChangeNotifierProvider<LanguageProvider>(create: (context) => LanguageProvider()) ,
    ],
    child: const MyApp(),
  ),);
}



Future<bool> checkIfUserIsAdmin() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return false;

  final doc =
  await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return doc.data()?['isAdmin'] ?? false;
}


Future<void> requestPermissions() async {
  List<Permission> permissions = [
    // Permission.camera,
    Permission.photos,
    Permission.location,
  ];


  if (!kIsWeb) {
    permissions.addAll([
      Permission.storage,
      Permission.photos,
    ]);
  }
  permissions = permissions.where((p) => p != Permission.photos || !kIsWeb).toList();

  await permissions.request();
}

@override
void initState() {
  requestPermissions();
}

class MyApp extends StatelessWidget {
   const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return
      MaterialApp(
      debugShowCheckedModeBanner: false,

        localizationsDelegates: const [

          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,

          AppLocalizations.delegate,

        ],
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],

        locale: Locale(Provider .of<LanguageProvider> (context, listen: true).language),

      initialRoute:'/login',
      routes: {
        '/launch': (context) => const LaunchScreen(),
        '/login': (context) => const LoginScreen(),
        '/upload': (context) => const UploadFileScreen(),
        '/home': (context) => const HomeScreen(),
        '/invoice': (context) => const NameForm(),
        '/search': (context) => const SearchScreen(),
        '/chat': (context) => const ChatScreen(),
        '/chatt': (context) => const PrivetChatScreen(userEmail: ''),
        '/profile': (context) => const ProfileFormScreen(),
        '/edit': (context) => const ProfileDetailsScreen(),
        '/admin': (context) => const AdminScreen(),
        '/user': (context) => const UserProfilesScreen(),
        '/AdminnScreen': (context) => const SendScreen(email: ''),
        '/FileUploadScreen': (context) => const Favorites(),
        '/my_cv_screen': (context) => const MyCVScreen(),
        '/map': (context) =>   MapScreen(),
      },
    );
  }
}