import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FangDetailPage extends StatefulWidget {
  final String catchId;
  const FangDetailPage({super.key, required this.catchId});

  @override
  State<FangDetailPage> createState() => _FangDetailPageState();
}

class _FangDetailPageState extends State<FangDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;
  bool _sent = false;

  Future<void> _addComment(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
      _sent = false;
    });

    final commentRef = FirebaseFirestore.instance
        .collection('catches')
        .doc(widget.catchId)
        .collection('comments')
        .doc();

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final username = userDoc.data()?['username'] ?? user.email;

    await commentRef.set({
      'userId': user.uid,
      'username': username,
      'text': text.trim(),
      'timestamp': Timestamp.now(),
      'likes': 0,
      'likedBy': [],
    });

    await _handleXP(user.uid);

    _commentController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = false;
      _sent = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    setState(() => _sent = false);
  }

  Future<void> _handleXP(String uid) async {
    final now = DateTime.now();
    final todayStart = Timestamp.fromDate(DateTime(now.year, now.month, now.day));

    final commentToday = await FirebaseFirestore.instance
        .collection('catches')
        .doc(widget.catchId)
        .collection('comments')
        .where('userId', isEqualTo: uid)
        .where('timestamp', isGreaterThan: todayStart)
        .get();

    if (commentToday.size <= 10) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final xp = snapshot['xp'] ?? 0;
        final level = snapshot['level'] ?? 1;
        final newXP = xp + 2;

        int newLevel = level;
        int requiredXP = (100 * level).toInt();
        if (newXP >= requiredXP) {
          newLevel++;
        }

        transaction.update(userRef, {
          'xp': newXP,
          'level': newLevel,
        });
      });
    }
  }

  Future<void> _toggleCommentLike(String commentId, List likedBy, bool hasLiked) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('catches')
        .doc(widget.catchId)
        .collection('comments')
        .doc(commentId);

    await ref.update({
      'likedBy': hasLiked ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final catchRef = FirebaseFirestore.instance.collection('catches').doc(widget.catchId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fangdetails"),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: catchRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final data = snapshot.data!.data() as Map<String, dynamic>;
              if (data['userId'] != userId) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await catchRef.delete();
                  Navigator.pop(context);
                },
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: catchRef.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final data = snap.data!.data() as Map<String, dynamic>;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Image.network(data['imageUrl'], fit: BoxFit.cover),
                      const SizedBox(height: 12),
                      Text("Fischart: ${data['fishType'] ?? ''}"),
                      Text("Köder: ${data['bait'] ?? ''}"),
                      Text("Technik: ${data['technique'] ?? ''}"),
                      Text("Gewicht: ${data['weight']} kg"),
                      Text("Länge: ${data['length']} cm"),
                      Text("Ort: ${data['location']}"),
                      Text("Von: ${data['username']}"),
                      const SizedBox(height: 16),
                      const Text("Kommentare", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: catchRef.collection('comments').orderBy('timestamp', descending: true).snapshots(),
                        builder: (context, commentSnap) {
                          if (!commentSnap.hasData) return const CircularProgressIndicator();
                          final comments = commentSnap.data!.docs;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: comments.map((doc) {
                              final c = doc.data() as Map<String, dynamic>;
                              final time = (c['timestamp'] as Timestamp).toDate();
                              final likedBy = List<String>.from(c['likedBy'] ?? []);
                              final hasLiked = likedBy.contains(userId);
                              return ListTile(
                                title: Text(c['username'] ?? ''),
                                subtitle: Text(c['text'] ?? ''),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("${likedBy.length}"),
                                    IconButton(
                                      icon: Icon(
                                        Icons.favorite,
                                        color: hasLiked ? Colors.red : Colors.grey,
                                      ),
                                      onPressed: () => _toggleCommentLike(doc.id, likedBy, hasLiked),
                                    ),
                                    Text("${time.hour}:${time.minute.toString().padLeft(2, '0')}")
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 90),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(hintText: "Kommentieren..."),
                    ),
                  ),
                  if (_isSending)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: CircularProgressIndicator(),
                    )
                  else if (_sent)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.check, color: Colors.green),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _addComment(_commentController.text),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
