import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataUploader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> _isAdmin() async {
    User? user = _auth.currentUser;
    if (user == null) {
      return false; // Not logged in, not an admin
    }

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      // Safely access the data and check the role
      var data = userDoc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('role')) {
        return data['role'] == 'admin';
      }
    }
    return false; // No role field or document doesn't exist
  }

  Future<void> uploadData() async {
    try {
      // 1. Check if the user is an admin
      bool isAdmin = await _isAdmin();
      if (!isAdmin) {
        throw Exception("Permission denied: User is not an admin.");
      }

      // 2. Baca file JSON dari assets
      final String response = await rootBundle.loadString('assets/vocab_data.json');
      final Map<String, dynamic> data = await json.decode(response);

      // Gunakan batch untuk upload sekaligus
      WriteBatch batch = _firestore.batch();

      // 3. Proses Data Vocab
      data.forEach((category, wordsList) {
        // Ensure wordsList is of the correct type
        if (wordsList is List) {
          DocumentReference docRef = _firestore.collection('vocab').doc(category);
          batch.set(docRef, {'words': wordsList});
        }
      });

      // 4. Kirim semua ke Firebase
      await batch.commit();
      debugPrint("✅ Upload Data JSON Berhasil!");

    } catch (e) {
      debugPrint("❌ Gagal Upload: $e");
      rethrow; // Lempar error agar UI tahu kalau gagal
    }
  }
}
