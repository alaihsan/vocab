import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vocab/firebase_options.dart';
import 'package:vocab/data/sample_data.dart';
import 'package:vocab/services/database_service.dart';
// Pastikan nama file ini sesuai dengan yang kamu buat (data_uploader.dart atau firestore_uploader.dart)
import 'package:vocab/services/data_uploader.dart'; 

// --- PALETTE ---
const Color kSageGreen = Color(0xFF739072);
const Color kDeepGreen = Color(0xFF3A4D39);
const Color kSoftCream = Color(0xFFECEEEC);
const Color kBackground = Color(0xFFF5F7F5);
const Color kTextDark = Color(0xFF1F2937);

// --- SERVICES (AUTH & STORAGE) ---
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignored
    }
    await _auth.signOut();
  }
}

class StorageService {
  static const String _completedCategoriesKey = 'completed_categories';
  static const String _completedQuizzesKey = 'completed_quizzes';
  static const String _userNameKey = 'user_name';
  static const String _historyKey = 'learning_history';

  Future<Set<String>> getCompletedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_completedCategoriesKey) ?? [];
    return list.toSet();
  }

  Future<void> saveCompletedCategories(Set<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedCategoriesKey, categories.toList());
  }

  Future<int> getCompletedQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_completedQuizzesKey) ?? 0;
  }

  Future<void> saveCompletedQuizzes(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_completedQuizzesKey, count);
  }

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? 'Learner';
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    return historyJson.map((json) {
      final parts = json.split('|');
      return {
        'type': parts[0],
        'name': parts[1],
        'timestamp': DateTime.parse(parts[2]),
        'score': parts.length > 3 ? parts[3] : null,
      };
    }).toList();
  }

  Future<void> addHistoryEntry(String type, String name, [String? score]) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    final timestamp = DateTime.now().toIso8601String();
    final entry = '$type|$name|$timestamp${score != null ? '|$score' : ''}';
    history.insert(0, entry);
    if (history.length > 100) history.removeLast();
    await prefs.setStringList(_historyKey, history);
  }
}

// --- MAIN ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
  runApp(const VocabZenApp());
}

class VocabZenApp extends StatelessWidget {
  const VocabZenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocab Zen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackground,
        useMaterial3: true,
        textTheme: GoogleFonts.zenKakuGothicAntiqueTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: kSageGreen),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const DashboardPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

// --- LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class AnimatedLoginBackground extends StatefulWidget {
  const AnimatedLoginBackground({super.key});
  @override
  State<AnimatedLoginBackground> createState() => _AnimatedLoginBackgroundState();
}

class _AnimatedLoginBackgroundState extends State<AnimatedLoginBackground> with TickerProviderStateMixin {
  late AnimationController _gradientController;
  
  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(duration: const Duration(seconds: 5), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [kSageGreen.withAlpha(77), kBackground, kDeepGreen.withAlpha(51)],
            ),
          ),
        );
      },
    );
  }
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _showEmailForm = false;
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi email dan password')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailPassword(_emailController.text, _passwordController.text);
    } catch (e) {
      // Auto-Register Logic
      if (e.toString().contains('user-not-found')) {
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } catch (regError) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal daftar: $regError')));
        }
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedLoginBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Vocab.", style: TextStyle(fontSize: 64, fontWeight: FontWeight.w300, letterSpacing: -2, color: kDeepGreen)),
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: kDeepGreen.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        children: [
                          if (!_showEmailForm) ...[
                            _buildButton(
                              text: "Continue with Google", icon: Icons.login,
                              onTap: () async {
                                setState(() => _isLoading = true);
                                try {
                                  await _authService.signInWithGoogle();
                                } catch (e) {
                                  setState(() => _isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              },
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => setState(() => _showEmailForm = true),
                              child: Text("Or sign in with email", style: TextStyle(color: kDeepGreen, fontWeight: FontWeight.w500, decoration: TextDecoration.underline)),
                            ),
                          ] else ...[
                            TextField(controller: _emailController, decoration: const InputDecoration(hintText: "Email")),
                            const SizedBox(height: 12),
                            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(hintText: "Password")),
                            const SizedBox(height: 24),
                            _buildButton(
                              text: "Sign In / Register", icon: Icons.login,
                              onTap: _handleEmailLogin, isLoading: _isLoading,
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => setState(() => _showEmailForm = false),
                              child: Text("Back to Google sign in"),
                            ),
                          ],
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({required String text, required IconData icon, required VoidCallback onTap, bool isLoading = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: kDeepGreen, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white), const SizedBox(width: 12), Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]),
        ),
      ),
    );
  }
}

// --- DASHBOARD ---
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final StorageService _storageService = StorageService();
  final User? _user = FirebaseAuth.instance.currentUser;
  late Future<List<String>> _vocabCategoriesFuture;
  late Future<Map<String, dynamic>> _grammarQuizFuture;
  
  String _userName = 'Learner'; // Default value
  bool _isAdmin = false;
  final Set<String> completedCategories = {};
  int completedQuizzes = 0;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _initData();
  }

  // Cek apakah user admin di Firestore
  Future<void> _checkAdminRole() async {
    if (_user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
        if (doc.exists && doc.data()?['role'] == 'admin') {
          if (mounted) setState(() => _isAdmin = true);
        }
      } catch (e) {
        print("Admin check error: $e");
      }
    }
  }

  Future<void> _initData() async {
    // Jangan panggil DatabaseService.initialize() otomatis di sini jika permission ketat
    await _loadPersistentData();
    if (_user?.displayName != null) {
      setState(() => _userName = _user!.displayName!);
      _storageService.saveUserName(_userName);
    }
    setState(() {
      _vocabCategoriesFuture = _fetchVocabCategories();
      _grammarQuizFuture = Future.value(sampleGrammarQuiz);
    });
  }

  Future<void> _loadPersistentData() async {
    final categories = await _storageService.getCompletedCategories();
    final quizzes = await _storageService.getCompletedQuizzes();
    final userName = await _storageService.getUserName();
    if (mounted) {
      setState(() {
        completedCategories.addAll(categories);
        completedQuizzes = quizzes;
        _userName = userName;
      });
    }
  }

  Future<List<String>> _fetchVocabCategories() async {
    return DatabaseService().getCategories();
  }

  void _markComplete(String category) {
    setState(() => completedCategories.add(category));
    _storageService.saveCompletedCategories(completedCategories);
    _storageService.addHistoryEntry('vocab', category);
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'travel': return Icons.card_travel;
      case 'noun': return Icons.lightbulb_outline;
      case 'kitchen': return Icons.kitchen;
      case 'technology': return Icons.computer;
      case 'space': return Icons.rocket_launch;
      default: return Icons.menu_book;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      // --- FAB UNTUK ADMIN UPLOAD JSON ---
      floatingActionButton: _isAdmin ? FloatingActionButton.extended(
        backgroundColor: kDeepGreen,
        icon: const Icon(Icons.cloud_upload, color: Colors.white),
        label: const Text("Upload JSON", style: TextStyle(color: Colors.white)),
        onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meng-upload data dari JSON...')));
          try {
            await DataUploader().uploadData();
            setState(() { _vocabCategoriesFuture = _fetchVocabCategories(); });
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Sukses! Data JSON masuk.')));
          } catch (e) {
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Gagal: $e')));
          }
        },
      ) : null,
      // -----------------------------------
      appBar: AppBar(
        backgroundColor: Colors.white.withAlpha(200),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Halo, ${_userName.split(' ')[0]}", style: const TextStyle(color: kTextDark, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(_isAdmin ? "Admin Access" : "Dashboard", style: TextStyle(color: _isAdmin ? Colors.red : Colors.grey[400], fontSize: 12, letterSpacing: 1.5)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.person, color: Colors.grey), onPressed: _showProfileBottomSheet)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Grammar Mastery", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _grammarQuizFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmerGrammarCard();
                return _buildGrammarCard(context);
              },
            ),
            const SizedBox(height: 32),
            const Text("Vocabulary Sets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            FutureBuilder<List<String>>(
              future: _vocabCategoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmerGrid();
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Belum ada data vocab.'));
                
                final categories = snapshot.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    String key = categories[index];
                    return _buildVocabCard(context, key, completedCategories.contains(key));
                  },
                );
              },
            ),
            // Practice Section (Optional)
            const SizedBox(height: 32),
            const Text("Practice Exercises", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildPracticeCard(context, 'Meaning Match', Icons.checklist, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeaningMatchPage())))),
                const SizedBox(width: 12),
                Expanded(child: _buildPracticeCard(context, 'Synonym Match', Icons.link, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SynonymMatchPage())))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CircleAvatar(radius: 30, backgroundColor: kSageGreen, backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null, child: _user?.photoURL == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null),
            const SizedBox(height: 16),
            Text(_user?.email ?? 'No Email'),
            if(_isAdmin) const Text("Administrator", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            SelectableText("UID: ${_user?.uid}", style: const TextStyle(fontSize: 10, color: Colors.grey)), // Helper copy UID
            const SizedBox(height: 24),
            OutlinedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryPage(storageService: _storageService))); }, child: const Text('Riwayat Belajar')),
            const SizedBox(height: 12),
            OutlinedButton(style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)), onPressed: () async { Navigator.pop(context); await AuthService().signOut(); }, child: const Text('Logout', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(77))), child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 12), Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kTextDark))])));
  }
  
  Widget _buildShimmerGrammarCard() => Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))));
  Widget _buildShimmerGrid() => Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1), itemCount: 4, itemBuilder: (context, index) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))));

  Widget _buildGrammarCard(BuildContext context) {
    return GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrammarQuizPage())), child: Container(height: 160, width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: kDeepGreen, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: kDeepGreen.withAlpha(77), blurRadius: 20, offset: const Offset(0, 10))]), child: Stack(children: [const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text("Daily Quiz", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text("10 Quick Questions", style: TextStyle(color: Colors.white70))]), const Positioned(right: 0, top: 0, bottom: 0, child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50))])));
  }

  Widget _buildVocabCard(BuildContext context, String title, bool isCompleted) {
    final categoryIcon = _getIconForCategory(title);
    return GestureDetector(onTap: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => VocabPlayerPage(category: title))); if (result == true) _markComplete(title); }, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.grey.withAlpha(13), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(categoryIcon, size: 24, color: kDeepGreen), if (isCompleted) const Icon(Icons.check_circle, size: 18, color: kSageGreen)]), Text(title[0].toUpperCase() + title.substring(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])));
  }
}

// --- VOCAB PLAYER (PERBAIKAN FITUR BACA DESKRIPSI) ---
// --- VOCAB PLAYER (FULL VERSION) ---
class VocabPlayerPage extends StatefulWidget {
  final String category;
  const VocabPlayerPage({super.key, required this.category});
  @override
  State<VocabPlayerPage> createState() => _VocabPlayerPageState();
}

class _VocabPlayerPageState extends State<VocabPlayerPage> {
  late Future<List<Map<String, dynamic>>> _wordsFuture;
  
  @override
  void initState() {
    super.initState();
    _wordsFuture = _fetchWords(widget.category);
  }

  Future<List<Map<String, dynamic>>> _fetchWords(String category) async {
    final dbService = DatabaseService();
    final words = await dbService.getVocabularyByCategory(category);
    if (words.isNotEmpty) {
      return words.map((w) => {
        'word': w['word']?.toString() ?? 'No Word',
        'pronounce': w['pronounce']?.toString() ?? '-',
        'desc': w['desc']?.toString() ?? w['description']?.toString() ?? 'No Meaning Available',
      }).toList();
    }
    throw Exception('Words not found.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _wordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: Text("No data"));
          return VocabPlayerView(words: snapshot.data!);
        },
      ),
    );
  }
}

class VocabPlayerView extends StatefulWidget {
  final List<Map<String, dynamic>> words;
  const VocabPlayerView({super.key, required this.words});
  @override
  State<VocabPlayerView> createState() => _VocabPlayerViewState();
}

class _VocabPlayerViewState extends State<VocabPlayerView> {
  int currentIndex = 0;
  late ConfettiController _confettiController;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2960/2960-preview.mp3'));
    } catch (e) { /* Ignore */ }
  }

  void _nextCard() {
    if (currentIndex < widget.words.length - 1) {
      setState(() => currentIndex++);
    } else {
      _confettiController.play();
      _playSuccessSound();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Center(
                child: FlippableCard(word: Map<String, String>.from(widget.words[currentIndex])),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: currentIndex == 0 ? null : () => setState(() => currentIndex--),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text("${currentIndex + 1} / ${widget.words.length}"),
                  IconButton(
                    onPressed: _nextCard,
                    icon: Icon(currentIndex == widget.words.length - 1 ? Icons.check : Icons.arrow_forward),
                    style: IconButton.styleFrom(backgroundColor: kDeepGreen, foregroundColor: Colors.white),
                  ),
                ],
              ),
            )
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 20,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
          ),
        ),
      ],
    );
  }
}

class FlippableCard extends StatefulWidget {
  final Map<String, String> word;
  const FlippableCard({super.key, required this.word});
  @override
  State<FlippableCard> createState() => _FlippableCardState();
}

class _FlippableCardState extends State<FlippableCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool showBack = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _flipCard() {
    if (showBack) { _controller.reverse(); } else { _controller.forward(); }
    setState(() => showBack = !showBack);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isBack = angle >= (pi / 2);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
            child: isBack
                ? Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(pi), child: _buildCardBack(widget.word))
                : _buildCardFront(widget.word),
          );
        },
      ),
    );
  }

  Widget _buildCardFront(Map<String, String> word) {
    return Container(
      width: 300, height: 400,
      decoration: BoxDecoration(color: kSageGreen, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      alignment: Alignment.center,
      child: Text(word['word']!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildCardBack(Map<String, String> word) {
    return Container(
      width: 300, height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: kDeepGreen, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(word['word']!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kSoftCream)),
          const SizedBox(height: 8),
          Text(word['pronounce']!, style: TextStyle(fontSize: 14, color: kSoftCream.withAlpha(150), fontFamily: 'Courier')),
          const SizedBox(height: 24),
          Text(word['desc']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    );
  }
}

// --- PLACEHOLDER UNTUK HALAMAN LAIN (AGAR TIDAK ERROR IMPORT) ---
// (Anda bisa mengganti ini dengan kode lengkap GrammarQuizPage dll jika mau)
class GrammarQuizPage extends StatelessWidget { const GrammarQuizPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title:const Text("Grammar")), body:const Center(child:Text("Quiz Coming Soon"))); }
class MeaningMatchPage extends StatelessWidget { const MeaningMatchPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title:const Text("Meaning Match")), body:const Center(child:Text("Practice Coming Soon"))); }
class SynonymMatchPage extends StatelessWidget { const SynonymMatchPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title:const Text("Synonym Match")), body:const Center(child:Text("Practice Coming Soon"))); }
class HistoryPage extends StatelessWidget { final StorageService storageService; const HistoryPage({super.key, required this.storageService}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title:const Text("History")), body:const Center(child:Text("History Coming Soon"))); }