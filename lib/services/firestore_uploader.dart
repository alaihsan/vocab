import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocab/data/sample_data.dart';

class FirestoreUploaderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadSampleData() async {
    // Batch write for vocabulary
    final vocabBatch = _firestore.batch();
    sampleVocab.forEach((category, words) {
      final docRef = _firestore.collection('vocab').doc(category);
      vocabBatch.set(docRef, {'words': words});
    });
    await vocabBatch.commit();

    // Single write for grammar quiz
    final grammarDocRef = _firestore.collection('grammar').doc('quiz1');
    await grammarDocRef.set(sampleGrammarQuiz);
  }
}
