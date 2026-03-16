import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chatapp/screens/login_screen.dart';
import 'package:chatapp/screens/chat_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // Listens to login/logout events continuously
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {

        // Show a loading spinner while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
          );
        }

        // Check if there is a valid user session
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // User is authenticated! Send them to the Chat
          return const ChatScreen();
        } else {
          // No user session, send them to Login
          return const LoginScreen();
        }
      },
    );
  }
}