import 'package:chatapp/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chatapp/screens/login_screen.dart';

Future<void> main() async {
  // Required to ensure Flutter framework is ready before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Supabase client
  await Supabase.initialize(
    url: 'https://jvrgonjrabowniwupntx.supabase.co',
    anonKey: 'sb_publishable_RfEaCd53YzKnBliO00vQIQ_j5AFhJNI',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Matches your dark UI approach
      home: const AuthGate(),
    );
  }
}