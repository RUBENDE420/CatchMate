import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'fang_detail_page.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fänge")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('catches')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Fehler beim Laden des Feeds'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Noch keine Fänge vorhanden'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              final catchId = data.id;
              return Card(
                margin: const EdgeInsets.all(12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FangDetailPage(catchId: catchId),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      data['imageUrl'] != null
                          ? Image.network(data['imageUrl'], fit: BoxFit.cover, height: 200, width: double.infinity)
                          : const SizedBox.shrink(),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['fishType'] ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("${data['length']} cm • ${data['weight']} kg"),
                            Text("${data['location']} • ${(data['timestamp'] as Timestamp).toDate().toLocal().toString().split(' ').first}"),  
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.favorite_border, size: 20),
                                const SizedBox(width: 4),
                                Text('${data['likes'] ?? 0} Likes'),
                                const SizedBox(width: 16),
                                const Icon(Icons.comment, size: 20),
                                const SizedBox(width: 4),
                                Text('${data['comments'] ?? 0} Kommentare'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
