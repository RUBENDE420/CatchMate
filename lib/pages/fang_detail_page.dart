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
  DocumentSnapshot? catchData;
  bool isLoading = true;
  String? error;
  bool isOwner = false;

  @override
  void initState() {
    super.initState();
    fetchCatch();
  }

  Future<void> fetchCatch() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('catches')
          .doc(widget.catchId)
          .get();

      if (!doc.exists) {
        setState(() {
          error = "Fang nicht gefunden.";
          isLoading = false;
        });
        return;
      }

      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      setState(() {
        catchData = doc;
        isOwner = doc['userId'] == currentUid;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Fehler beim Laden: $e";
        isLoading = false;
      });
    }
  }

  Future<void> deleteCatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fang löschen'),
        content: const Text('Möchtest du diesen Fang wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('catches')
          .doc(widget.catchId)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fang-Details"),
        actions: isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: deleteCatch,
                )
              ]
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : catchData == null
                  ? const Center(child: Text("Keine Daten verfügbar"))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.network(
                            catchData!['imageUrl'] ?? '',
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 16),
                          Text("Fischart: ${catchData!['fishType'] ?? '-'}", style: const TextStyle(fontSize: 18)),
                          Text("Köder: ${catchData!['bait'] ?? '-'}"),
                          Text("Technik: ${catchData!['technique'] ?? '-'}"),
                          Text("Gewicht: ${catchData!['weight'] ?? '-'} kg"),
                          Text("Länge: ${catchData!['length'] ?? '-'} cm"),
                          Text("Ort: ${catchData!['location'] ?? '-'}"),
                          Text(
                            "Datum: ${catchData!['timestamp'] != null ? (catchData!['timestamp'] as Timestamp).toDate().toLocal().toString().split(' ').first : '-'}",
                          ),
                          const SizedBox(height: 12),
                          Text("Likes: ${catchData!['likes'] ?? 0}"),
                          Text("Kommentare: ${catchData!['comments'] ?? 0}"),
                        ],
                      ),
                    ),
    );
  }
}
