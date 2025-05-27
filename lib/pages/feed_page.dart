import 'package:flutter/material.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fänge'),
      ),
      body: ListView.builder(
        itemCount: 10, // Später mit Firestore-Daten ersetzen
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    CircleAvatar(radius: 20, backgroundImage: AssetImage('assets/user.png')),
                    SizedBox(width: 10),
                    Text('Benutzername', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(Icons.image, size: 60)),
                ),
                const SizedBox(height: 10),
                const Text('Hecht • 94 cm • 6,2 kg'),
                const SizedBox(height: 6),
                const Text('Veluwemeer, 24.05.2025'),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Icon(Icons.favorite_border),
                    SizedBox(width: 8),
                    Text('24 Likes'),
                    Spacer(),
                    Icon(Icons.comment),
                    SizedBox(width: 8),
                    Text('5 Kommentare'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
