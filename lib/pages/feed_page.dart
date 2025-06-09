import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'fang_detail_page.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  Future<bool> hasLiked(String catchId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final likeDoc = await FirebaseFirestore.instance
        .collection("catches")
        .doc(catchId)
        .collection("likes")
        .doc(uid)
        .get();
    return likeDoc.exists;
  }

  Future<void> toggleLike(String catchId, String ownerId, bool isLiked) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final likeRef = FirebaseFirestore.instance
        .collection("catches")
        .doc(catchId)
        .collection("likes")
        .doc(uid);

    final catchRef = FirebaseFirestore.instance.collection("catches").doc(catchId);

    if (isLiked) {
      await likeRef.delete();
      await catchRef.update({'likes': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'timestamp': FieldValue.serverTimestamp()});
      await catchRef.update({'likes': FieldValue.increment(1)});
      if (uid != ownerId) {
        FirebaseFirestore.instance.collection("users").doc(ownerId).update({
          'xp': FieldValue.increment(5),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fänge")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("catches")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final catches = snapshot.data!.docs;

          return ListView.builder(
            itemCount: catches.length,
            itemBuilder: (context, index) {
              final doc = catches[index];
              final data = doc.data() as Map<String, dynamic>;
              final catchId = doc.id;
              final currentUser = FirebaseAuth.instance.currentUser;
              final currentUserId = currentUser?.uid;
              final ownerId = data['userId'];

              return FutureBuilder<bool>(
                future: hasLiked(catchId),
                builder: (context, likeSnap) {
                  final liked = likeSnap.data ?? false;
                  return Card(
                    margin: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(data['username'] ?? 'Benutzername'),
                        ),
                        GestureDetector(
                          onDoubleTap: () => toggleLike(catchId, ownerId, liked),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FangDetailPage(catchId: catchId),
                            ),
                          ),
                          child: Image.network(
                            data['imageUrl'] ?? '',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  liked ? Icons.favorite : Icons.favorite_border,
                                  color: liked ? Colors.red : Colors.grey,
                                ),
                                onPressed: () => toggleLike(catchId, ownerId, liked),
                              ),
                              Text("${data['likes'] ?? 0} Likes"),
                              const Spacer(),
                              const Icon(Icons.comment),
                              const SizedBox(width: 4),
                              Text("${data['comments'] ?? 0} Kommentare"),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "${data['fishType'] ?? ''} • ${data['length']} cm • ${data['weight']} kg",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Text(
                            "${data['location']} • ${(data['timestamp'] as Timestamp).toDate().toLocal().toString().split(' ').first}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
