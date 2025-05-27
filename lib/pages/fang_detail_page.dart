import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FangDetailPage extends StatelessWidget {
  final String catchId;
  const FangDetailPage({super.key, required this.catchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fang-Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('catches').doc(catchId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Fang nicht gefunden."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                if (data['imageUrl'] != null)
                  Image.network(data['imageUrl'], height: 250, fit: BoxFit.cover),
                const SizedBox(height: 16),
                _buildInfoTile("Fischart", data['fishType']),
                if (data['weight'] != null)
                  _buildInfoTile("Gewicht", "${data['weight']} kg"),
                if (data['method'] != null)
                  _buildInfoTile("Angeltechnik", data['method']),
                if (data['bait'] != null)
                  _buildInfoTile("Köder", data['bait']),
                if (data['timestamp'] != null)
                  _buildInfoTile(
                    "Gefangen am",
                    (data['timestamp'] as Timestamp).toDate().toString(),
                  ),
                if (data['location'] != null)
                  _buildInfoTile("GPS Position",
                      "${data['location']['lat']}, ${data['location']['lng']}"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
