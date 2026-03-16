import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class DirectMessageScreen extends StatefulWidget {
  final String conversationId;
  final String otherUsername;

  const DirectMessageScreen({
    super.key,
    required this.conversationId,
    required this.otherUsername,
  });

  @override
  State<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  final _messageController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  final _myId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    // 3. Set up the filtered stream
    _messagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: false);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await Supabase.instance.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _myId,
        'content': text,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.otherUsername, style: GoogleFonts.inter(color: Colors.white)),
      ),
      body: Column(
        children: [
          // 4a. The Message List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(child: Text('Say hi!', style: GoogleFonts.inter(color: Colors.grey)));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message['sender_id'] == _myId;

                      // 1. Parse the raw database string into a local Dart DateTime object
                      final createdAt = DateTime.parse(message['created_at']).toLocal();
                      // 2. Format it into a clean, readable time (e.g., "10:42 AM")
                      final timeString = TimeOfDay.fromDateTime(createdAt).format(context);

                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        // Wrap in a Column so we can stack the bubble and the timestamp
                        child: Column(
                          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMine ? const Color(0xFF016239) : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                message['content'],
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),

                            // 3. The newly added Timestamp text
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                              child: Text(
                                timeString,
                                style: GoogleFonts.inter(color: Colors.grey, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                );
              },
            ),
          ),

          // 4b. The Input Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) => _sendMessage(),
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF016239),
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}