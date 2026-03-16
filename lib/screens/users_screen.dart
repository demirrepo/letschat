import 'package:chatapp/screens/direct_messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // We use a Future to fetch the profiles exactly once when the screen opens
  late final Future<List<Map<String, dynamic>>> _futureUsers;

  @override
  void initState() {
    super.initState();
    // Get the current user's ID
    final myUserId = Supabase.instance.client.auth.currentUser!.id;

    // Fetch all profiles WHERE the id does NOT EQUAL myUserId
    _futureUsers = Supabase.instance.client
        .from('profiles')
        .select()
        .neq('id', myUserId);
  }

  Future<void> _startChat(String otherUserId, String otherUsername) async {
    try {
      final myId = Supabase.instance.client.auth.currentUser!.id;

      // 1. Check if a conversation ALREADY exists between you two
      final existingChat = await Supabase.instance.client
          .from('user_inbox')
          .select('conversation_id')
          .eq('my_id', myId)
          .eq('other_user_id', otherUserId)
          .maybeSingle(); // Returns the row if found, or null if it doesn't exist

      String conversationId;

      if (existingChat != null) {
        // 2a. Chat exists! Just use the old ID.
        conversationId = existingChat['conversation_id'];
      } else {
        // 2b. No chat exists. Create a brand new one.
        final conversation = await Supabase.instance.client
            .from('conversations')
            .insert({})
            .select()
            .single();

        conversationId = conversation['id'];

        await Supabase.instance.client.from('participants').insert([
          {'conversation_id': conversationId, 'profile_id': myId},
          {'conversation_id': conversationId, 'profile_id': otherUserId},
        ]);
      }

      if (!mounted) return;

      // 3. Navigate using whichever ID we ended up with
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DirectMessageScreen(
            conversationId: conversationId,
            otherUsername: otherUsername,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Text('New Chat', style: GoogleFonts.inter(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading users', style: GoogleFonts.inter(color: Colors.red)));
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Text('No other users found.', style: GoogleFonts.inter(color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF016239),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  user['username'] ?? 'Unknown User',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                 _startChat(user['id'], user['username']);
                },
              );
            },
          );
        },
      ),
    );
  }
}