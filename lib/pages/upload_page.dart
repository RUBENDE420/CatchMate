import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'fang_detail_page.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final fishTypeController = TextEditingController();
  final weightController = TextEditingController();
  final methodController = TextEditingController();
  final baitController = TextEditingController();

  File? imageFile;
  bool isLoading = false;
  String? error;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => imageFile = File(picked.path));
    }
  }

  Future<void> uploadCatch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fishType = fishTypeController.text.trim();
    final weight = weightController.text.trim();
    final method = methodController.text.trim();
    final bait = baitController.text.trim();

    if (imageFile == null || fishType.isEmpty) {
      setState(() => error = "Bitte Bild und Fischart angeben");
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final uid = user.uid;
      final catchId = FirebaseFirestore.instance.collection('catches').doc().id;
      final ref = FirebaseStorage.instance.ref().child('catches/$uid/$catchId.jpg');

      await ref.putFile(imageFile!);
      final imageUrl = await ref.getDownloadURL();

      final position = await Geolocator.getCurrentPosition();

      final data = {
        'userId': uid,
        'imageUrl': imageUrl,
        'fishType': fishType,
        'weight': weight.isNotEmpty ? double.tryParse(weight) : null,
        'method': method,
        'bait': bait,
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        }
      };

      await FirebaseFirestore.instance.collection('catches').doc(catchId).set(data);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FangDetailPage(catchId: catchId),
          ),
        );
      }
    } catch (e) {
      setState(() => error = "Fehler beim Hochladen");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fang hochladen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (imageFile != null)
                Image.file(imageFile!, height: 180)
              else
                TextButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text("Bild auswählen"),
                  onPressed: pickImage,
                ),
              const SizedBox(height: 12),
              TextField(
                controller: fishTypeController,
                decoration: const InputDecoration(labelText: 'Fischart'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Gewicht (optional in KG)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: methodController,
                decoration: const InputDecoration(labelText: 'Angeltechnik (z.B. Spinnfischen)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baitController,
                decoration: const InputDecoration(labelText: 'Köder (z.B. Wobbler, Made...)'),
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: uploadCatch,
                  child: const Text("Fang hochladen"),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                )
            ],
          ),
        ),
      ),
    );
  }
}
