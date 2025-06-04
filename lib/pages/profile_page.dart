import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'fang_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _bioController = TextEditingController();
  final picker = ImagePicker();
  bool _isUpdating = false;

  Future<void> _pickAndUploadImage(String uid) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final storageRef = FirebaseStorage.instance.ref().child("profile_images/$uid.jpg");
    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "profileImage": downloadUrl,
    });

    setState(() {});
  }

  Future<void> _updateBio(String uid) async {
    setState(() => _isUpdating = true);
    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "bio": _bioController.text,
    });
    setState(() => _isUpdating = false);
  }

  int _calculateLevelTarget(int level) => 100 * level;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Mein Profil")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
          final userData = userSnap.data!.data() as Map<String, dynamic>;
          final username = userData["username"] ?? "Unbekannt";
          final bio = userData["bio"] ?? "";
          final xp = userData["xp"] ?? 0;
          final level = userData["level"] ?? 1;
          final followers = userData["followers"] ?? 0;
          final following = userData["following"] ?? 0;
          final profileImage = userData["profileImage"];

          _bioController.text = bio;
          final levelTarget = _calculateLevelTarget(level);
          final levelProgress = xp / levelTarget;

          return Column(
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _pickAndUploadImage(uid),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                  child: profileImage == null ? const Icon(Icons.person, size: 50) : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: "Bio bearbeiten",
                    suffixIcon: _isUpdating
                        ? const CircularProgressIndicator()
                        : IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: () => _updateBio(uid),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Level: $level"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("$xp XP"),
                        Text("$levelTarget XP"),
                      ],
                    ),
                    LinearProgressIndicator(value: levelProgress.clamp(0.0, 1.0)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Follower: $followers"),
                        const SizedBox(width: 16),
                        Text("Gefolgt: $following"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Meine Fänge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("catches")
                      .where("userId", isEqualTo: uid)
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
                  builder: (context, catchSnap) {
                    if (!catchSnap.hasData) return const Center(child: CircularProgressIndicator());
                    final catches = catchSnap.data!.docs;
                    if (catches.isEmpty) return const Center(child: Text("Keine Fänge vorhanden."));

                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: catches.length,
                      itemBuilder: (context, index) {
                        final doc = catches[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return AspectRatio(
                          aspectRatio: 1,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FangDetailPage(catchId: doc.id),
                                ),
                              );
                            },
                            child: Image.network(
                              data['imageUrl'] ?? '',
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}