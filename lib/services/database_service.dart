import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new document for the user in the 'users' collection
  /// with a default role of 'user'.
  Future<void> createUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'role': 'user', // Default role
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error creating user document: $e");
    }
  }

  /// Sets a user's role. This function should be protected and only
  /// accessible by other admins.
  Future<void> setUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': role});
      debugPrint("Successfully updated role for user $uid to $role");
    } catch (e) {
      debugPrint("Error setting user role: $e");
    }
  }

  /// Inisialisasi: Cek apakah data sudah ada di Firebase.
  /// Jika belum (kosong), kita upload data bawaan (seeding).
  static Future<void> initialize() async {
    final service = DatabaseService();
    await service._seedInitialDataIfNeeded();
  }

  /// Mengambil daftar Kategori (Document ID) dari koleksi 'vocab'
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('vocab').get();
      // Mengambil ID dokumen sebagai nama kategori
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint("Error getting categories: $e");
      return [];
    }
  }

  /// Mengambil daftar kata berdasarkan kategori
  Future<List<Map<String, dynamic>>> getVocabularyByCategory(String category) async {
    try {
      final docSnapshot = await _firestore.collection('vocab').doc(category).get();
      
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        // Pastikan field 'words' ada dan berupa List
        if (data['words'] is List) {
          return List<Map<String, dynamic>>.from(data['words']);
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error getting words for $category: $e");
      return [];
    }
  }

  // --- LOGIKA UPLOAD DATA AWAL (SEEDING) ---
  
  Future<void> _seedInitialDataIfNeeded() async {
    try {
      // Cek apakah koleksi 'vocab' kosong
      final snapshot = await _firestore.collection('vocab').limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint("Database kosong. Memulai upload data awal ke Firebase...");
        
        final batch = _firestore.batch();
        
        // Data bawaan (Hardcoded data dari file sebelumnya)
        final initialData = {
          'travel': [
            {'word': 'Journey', 'pronounce': '/ˈdʒɜːrni/', 'desc': 'An act of traveling from one place to another.'},
            {'word': 'Destination', 'pronounce': '/ˌdɛstɪˈneɪʃən/', 'desc': 'The place to which someone or something is going or being sent.'},
            {'word': 'Explore', 'pronounce': '/ɪkˈsplɔːr/', 'desc': 'Travel through (an unfamiliar area) in order to learn about it.'},
            {'word': 'Itinerary', 'pronounce': '/aɪˈtɪnərɛri/', 'desc': 'A planned route or journey.'},
            {'word': 'Voyage', 'pronounce': '/ˈvɔɪɪdʒ/', 'desc': 'A long journey involving travel by sea or in space.'},
            {'word': 'Adventure', 'pronounce': '/ədˈvɛntʃər/', 'desc': 'An unusual and exciting, typically hazardous, experience or activity.'},
            {'word': 'Passport', 'pronounce': '/ˈpæspɔːrt/', 'desc': 'An official document issued by a government, certifying the holder\'s identity and citizenship and entitling them to travel under its protection to and from foreign countries.'},
            {'word': 'Souvenir', 'pronounce': '/ˌsuːvəˈnɪər/', 'desc': 'A thing that is kept as a reminder of a person, place, or event.'},
            {'word': 'Navigate', 'pronounce': '/ˈnævɪɡeɪt/', 'desc': 'Plan and direct the route or course of a ship, aircraft, or other form of transportation, especially by using instruments or maps.'},
            {'word': 'Excursion', 'pronounce': '/ɪkˈskɜːrʒən/', 'desc': 'A short journey or trip, especially one engaged in as a leisure activity.'},
          ],
          'kitchen': [
            {'word': 'Spatula', 'pronounce': '/ˈspætʃələ/', 'desc': 'An implement with a broad, flat, blunt blade, used for mixing, spreading, and lifting.'},
            {'word': 'Whisk', 'pronounce': '/wɪsk/', 'desc': 'A utensil for whipping eggs or cream.'},
            {'word': 'Colander', 'pronounce': '/ˈkʌləndər/', 'desc': 'A perforated bowl used to strain off liquid from food, especially after cooking.'},
            {'word': 'Ladle', 'pronounce': '/ˈleɪdl/', 'desc': 'A large long-handled spoon with a cup-shaped bowl, used for serving soup, stew, or sauce.'},
            {'word': 'Grater', 'pronounce': '/ˈɡreɪtər/', 'desc': 'A device having a surface covered with holes with sharp edges for grating cheese and other foods.'},
            {'word': 'Knead', 'pronounce': '/niːd/', 'desc': 'Work (moistened flour or clay) into dough or paste with the hands.'},
            {'word': 'Simmer', 'pronounce': '/ˈsɪmər/', 'desc': 'Stay just below the boiling point while being heated.'},
            {'word': 'Braise', 'pronounce': '/breɪz/', 'desc': 'Fry (food) lightly and then stew it slowly in a closed container.'},
            {'word': 'Dice', 'pronounce': '/daɪs/', 'desc': 'Cut (food or other matter) into small cubes.'},
            {'word': 'Mince', 'pronounce': '/mɪns/', 'desc': 'Cut up or grind (food, especially meat) into very small pieces.'},
          ],
          'human body': [
            {'word': 'Vertebra', 'pronounce': '/ˈvɜːrtɪbrə/', 'desc': 'Each of the small bones forming the backbone or spine.'},
            {'word': 'Thorax', 'pronounce': '/ˈθɔːræks/', 'desc': 'The part of the body between the neck and the abdomen; the chest.'},
            {'word': 'Abdomen', 'pronounce': '/ˈæbdəmən/', 'desc': 'The part of the body between the chest and the pelvis.'},
            {'word': 'Biceps', 'pronounce': '/ˈbaɪsɛps/', 'desc': 'A muscle on the front of the upper arm.'},
            {'word': 'Femur', 'pronounce': '/ˈfiːmər/', 'desc': 'The thighbone; the longest and strongest bone in the human body.'},
            {'word': 'Cornea', 'pronounce': '/ˈkɔːrniə/', 'desc': 'The transparent layer forming the front of the eye.'},
            {'word': 'Trachea', 'pronounce': '/ˈtreɪkiə/', 'desc': 'The windpipe; the tube through which air passes to the lungs.'},
            {'word': 'Esophagus', 'pronounce': '/ɪˈsɑːfəɡəs/', 'desc': 'The tube connecting the pharynx and stomach.'},
            {'word': 'Ligament', 'pronounce': '/ˈlɪɡəmənt/', 'desc': 'A short band of tough tissue connecting bones or holding organs in place.'},
            {'word': 'Muscle', 'pronounce': '/ˈmʌsl/', 'desc': 'A tissue in the body that has the ability to contract, producing movement.'},
          ],
          'emotions': [
            {'word': 'Jubilant', 'pronounce': '/ˈdʒuːbɪlənt/', 'desc': 'Feeling or expressing great happiness and triumph.'},
            {'word': 'Melancholy', 'pronounce': '/ˈmɛlənkɑːli/', 'desc': 'A feeling of pensive sadness, typically with no obvious cause.'},
            {'word': 'Anxious', 'pronounce': '/ˈæŋkʃəs/', 'desc': 'Feeling worry, nervousness, or unease about something.'},
            {'word': 'Elated', 'pronounce': '/ɪˈleɪtɪd/', 'desc': 'Very happy or proud; in high spirits.'},
            {'word': 'Contempt', 'pronounce': '/kənˈtɛmpt/', 'desc': 'A feeling that someone or something is worthless; scorn.'},
            {'word': 'Serene', 'pronounce': '/səˈriːn/', 'desc': 'Calm, peaceful, and untroubled; tranquil.'},
            {'word': 'Exasperated', 'pronounce': '/ɪɡˈzæspəreɪtɪd/', 'desc': 'Annoyed or frustrated to the point of anger.'},
            {'word': 'Nostalgia', 'pronounce': '/nɑːˈstældʒə/', 'desc': 'Sentimental longing for the past, typically for a period or place with happy associations.'},
            {'word': 'Remorse', 'pronounce': '/rɪˈmɔːrs/', 'desc': 'Regret and repentance for past actions.'},
            {'word': 'Euphoria', 'pronounce': '/juːˈfɔːriə/', 'desc': 'A state of intense happiness and confidence.'},
          ],
          'noun': [
            {'word': 'Castle', 'pronounce': '/ˈkæsl/', 'desc': 'A large fortified building.'},
            {'word': 'Butterfly', 'pronounce': '/ˈbʌtərflaɪ/', 'desc': 'A flying insect with colorful wings.'},
            {'word': 'Computer', 'pronounce': '/kəmˈpjuːtər/', 'desc': 'An electronic device for processing data.'},
            {'word': 'Music', 'pronounce': '/ˈmjuːzɪk/', 'desc': 'Vocal or instrumental sounds combined in such a way as to produce beauty of form.'},
            {'word': 'Mountain', 'pronounce': '/ˈmaʊntən/', 'desc': 'A large natural elevation of the earth\'s surface.'},
            {'word': 'Ocean', 'pronounce': '/ˈoʊʃən/', 'desc': 'A very large expanse of sea.'},
            {'word': 'Umbrella', 'pronounce': '/ʌmˈbrɛlə/', 'desc': 'A canopy on a pole used as protection against rain.'},
            {'word': 'Telescope', 'pronounce': '/ˈtɛləskoʊp/', 'desc': 'An optical instrument used for viewing distant objects.'},
            {'word': 'Diamond', 'pronounce': '/ˈdaɪmənd/', 'desc': 'A precious stone consisting of a clear and hard form of carbon.'},
            {'word': 'Harmony', 'pronounce': '/ˈhɑːrməni/', 'desc': 'The state of being in agreement or accord.'},
          ],
        };

        // Loop untuk membuat dokumen di Firestore
        initialData.forEach((category, words) {
          final docRef = _firestore.collection('vocab').doc(category);
          batch.set(docRef, {'words': words});
        });

        await batch.commit();
        debugPrint("Upload data awal selesai!");
      } else {
        debugPrint("Database sudah berisi data. Melewati proses seeding.");
      }
    } catch (e) {
      debugPrint("Gagal melakukan seeding data: $e");
    }
  }
}