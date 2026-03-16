import 'package:chatapp/screens/direct_messages_screen.dart';
import 'package:chatapp/widgets/chat_list_item.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:chatapp/widgets/chat_list_item.dart'; // Make sure this file exists from Step 3.5!
import 'users_screen.dart';
import 'direct_messages_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _searchController = TextEditingController();
  final _myUserId = Supabase.instance.client.auth.currentUser!.id;

  // 1. A simple function to fetch our new Database View
  Future<List<Map<String, dynamic>>> _fetchInbox() async {
    final data = await Supabase.instance.client
        .from('user_inbox')
        .select()
        .eq('my_id', _myUserId); // Only get my conversations
    return data;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF016239),
        child: const Icon(Icons.message, color: Colors.white),
        onPressed: () async {
          // Wait until they return from the Users screen...
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UsersScreen()),
          );
          // ...then refresh the inbox to show any new chats!
          setState(() {});
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // The Search Bar and Logout Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search users and messages...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.greenAccent),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                    },
                  ),
                ],
              ),
            ),

            // 2. The Real Inbox Data
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchInbox(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }

                  final inboxItems = snapshot.data ?? [];

                  if (inboxItems.isEmpty) {
                    return Center(
                      child: Text('No active chats. Tap the button to start one!', style: GoogleFonts.inter(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    itemCount: inboxItems.length,
                    itemBuilder: (context, index) {
                      final item = inboxItems[index];
                      // Use the real message, or a fallback if the room is empty
                      final realLastMessage = item['last_message'] ?? 'Say hi!';

                      return ChatListItem(
                        username: item['other_username'] ?? 'Unknown User',
                        lastMessage: realLastMessage,
                        onTap: () async {
                          // 3. Navigate directly to the existing room
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DirectMessageScreen(
                                conversationId: item['conversation_id'],
                                otherUsername: item['other_username'],
                              ),
                            ),
                          );
                          // Refresh inbox when returning in case anything changed
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}