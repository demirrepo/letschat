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

  // 1. Store the Future so it doesn't refetch on every single keystroke
  late Future<List<Map<String, dynamic>>> _inboxFuture;

  @override
  void initState() {
    super.initState();
    _inboxFuture = _fetchInbox();

    // Listen to the text field and rebuild the UI every time a letter is typed
    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<List<Map<String, dynamic>>> _fetchInbox() async {
    final data = await Supabase.instance.client
        .from('user_inbox')
        .select()
        .eq('my_id', _myUserId);
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
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UsersScreen()),
          );
          // 2. Re-fetch the future when returning to the inbox
          setState(() {
            _inboxFuture = _fetchInbox();
          });
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
                        hintText: 'Search users...',
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
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                    },
                  ),
                ],
              ),
            ),

            // The Real Inbox Data
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _inboxFuture, // Use the stored future!
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }

                  final allItems = snapshot.data ?? [];

                  // 3. Filter the list based on what is typed in the search bar!
                  final searchQuery = _searchController.text.toLowerCase();
                  final filteredItems = allItems.where((item) {
                    final username = (item['other_username'] ?? '').toString().toLowerCase();
                    final message = (item['last_message'] ?? '').toString().toLowerCase();
                    // Keep the item if the search matches either the name or the message text
                    return username.contains(searchQuery) || message.contains(searchQuery);
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return Center(
                      child: Text('No chats found.', style: GoogleFonts.inter(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      // Use the FILTERED list here, not the original one!
                      final item = filteredItems[index];
                      final realLastMessage = item['last_message'] ?? 'Say hi!';

                      return ChatListItem(
                        username: item['other_username'] ?? 'Unknown User',
                        lastMessage: realLastMessage,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DirectMessageScreen(
                                conversationId: item['conversation_id'],
                                otherUsername: item['other_username'],
                              ),
                            ),
                          );
                          setState(() {
                            _inboxFuture = _fetchInbox();
                          });
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