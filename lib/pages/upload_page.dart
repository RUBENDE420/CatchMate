import 'dart:io';
import 'package:catchmate/pages/fang_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _image;
  final picker = ImagePicker();

  final _fishTypeController = TextEditingController();
  final _baitController = TextEditingController();
  final _techniqueController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isUploading = false;
  String? _error;

  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadCatch() async {
    if (_image == null) {
      setState(() {
        _error = "Bitte ein Bild auswählen.";
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Nicht eingeloggt");

      final storageRef = FirebaseStorage.instance
          .ref()
          .child("catches/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg");

      await storageRef.putFile(_image!);
      final imageUrl = await storageRef.getDownloadURL();

      final newCatch = await FirebaseFirestore.instance.collection('catches').add({
        'userId': user.uid,
        'username': user.displayName ?? user.email,
        'imageUrl': imageUrl,
        'fishType': _fishTypeController.text,
        'bait': _baitController.text,
        'technique': _techniqueController.text,
        'weight': double.tryParse(_weightController.text) ?? 0,
        'length': double.tryParse(_lengthController.text) ?? 0,
        'location': _locationController.text,
        'timestamp': Timestamp.now(),
        'likes': 0,
        'comments': 0,
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FangDetailPage(catchId: newCatch.id),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Fehler beim Hochladen: $e";
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fang hochladen")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 200,
                color: Colors.grey[800],
                child: _image == null
                    ? const Center(child: Icon(Icons.image, size: 50))
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _fishTypeController, decoration: const InputDecoration(labelText: "Fischart")),
            TextField(controller: _baitController, decoration: const InputDecoration(labelText: "Köder")),
            TextField(controller: _techniqueController, decoration: const InputDecoration(labelText: "Technik")),
            TextField(controller: _weightController, decoration: const InputDecoration(labelText: "Gewicht (kg)"), keyboardType: TextInputType.number),
            TextField(controller: _lengthController, decoration: const InputDecoration(labelText: "Länge (cm)"), keyboardType: TextInputType.number),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: "Ort")),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isUploading ? null : uploadCatch,
              child: _isUploading ? const CircularProgressIndicator() : const Text("Fang hochladen"),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}