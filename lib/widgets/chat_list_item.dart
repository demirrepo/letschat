import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatListItem extends StatelessWidget {
  final String username;
  final String lastMessage;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.username,
    required this.lastMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFF016239),
        radius: 28,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        username,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        lastMessage,
        style: GoogleFonts.inter(
          color: Colors.grey,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}