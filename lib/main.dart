import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
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

// --- PALETTE ---
// Warna Zen
const Color kSageGreen = Color(0xFF739072);
const Color kDeepGreen = Color(0xFF3A4D39);
const Color kSoftCream = Color(0xFFECEEEC);
const Color kBackground = Color(0xFFF5F7F5);
const Color kTextDark = Color(0xFF1F2937);

// --- SERVICES ---
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
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
      // User might not be logged in with Google, that's okay
    }
    await _auth.signOut();
  }
}

// --- STORAGE SERVICE ---
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
        'type': parts[0], // 'vocab' or 'quiz'
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
    history.insert(0, entry); // Add to beginning for latest first
    if (history.length > 100) history.removeLast(); // Keep only last 100
    await prefs.setStringList(_historyKey, history);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.initialize();
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

// --- AUTH WRAPPER ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          // Handle error gracefully - show login page instead of red error screen
          return const LoginPage();
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

// --- 1. LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// --- ANIMATED LOGIN BACKGROUND ---
class AnimatedLoginBackground extends StatefulWidget {
  const AnimatedLoginBackground({super.key});

  @override
  State<AnimatedLoginBackground> createState() => _AnimatedLoginBackgroundState();
}

class _AnimatedLoginBackgroundState extends State<AnimatedLoginBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _floatController;
  late List<AnimationController> _particleControllers;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _particleControllers = List.generate(
      8,
      (index) => AnimationController(
        duration: Duration(seconds: 6 + (index * 1)),
        vsync: this,
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _floatController.dispose();
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kSageGreen.withValues(
                      alpha: 0.3 + (_gradientController.value * 0.2),
                    ),
                    kBackground,
                    kDeepGreen.withValues(
                      alpha: 0.2 + (_gradientController.value * 0.15),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // Floating particles
        ..._particleControllers.asMap().entries.map((e) {
          int index = e.key;
          AnimationController controller = e.value;

          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Positioned(
                left: MediaQuery.of(context).size.width * (0.1 + (index * 0.12)),
                top: MediaQuery.of(context).size.height * (0.2 + (controller.value * 0.4)),
                child: Container(
                  width: 15 + (index * 5),
                  height: 15 + (index * 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: [
                      kSageGreen,
                      kDeepGreen,
                      Colors.cyan,
                    ][index % 3].withAlpha(51),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _showEmailForm = false;
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
      // On success, AuthWrapper will handle navigation
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String errorMessage = 'Failed to sign in';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'User not found';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Wrong password';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email format';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
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
                    const Text(
                      "Vocab.",
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -2,
                        color: kDeepGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "MASTERY THROUGH SERENITY",
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 3,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(153),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withAlpha(204)),
                        boxShadow: [
                          BoxShadow(
                            color: kDeepGreen.withAlpha(13),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          if (!_showEmailForm)
                            Column(
                              children: [
                                Text(
                                  "Start your language journey with a peace of mind.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: kTextDark.withAlpha(179),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildButton(
                                  text: "Continue with Google",
                                  icon: Icons.login,
                                  onTap: () async {
                                    if (_isLoading) return;
                                    setState(() => _isLoading = true);
                                    try {
                                      await _authService.signInWithGoogle();
                                    } catch (e) {
                                      if (!mounted) return;
                                      setState(() => _isLoading = false);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('Failed to sign in: $e')),
                                      );
                                    }
                                  },
                                  isLoading: _isLoading,
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _showEmailForm = true);
                                  },
                                  child: Text(
                                    "Or sign in with email",
                                    style: TextStyle(
                                      color: kDeepGreen,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Text(
                                  "Sign in with Email",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: kTextDark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    hintText: "Email",
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  enabled: !_isLoading,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    hintText: "Password",
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  enabled: !_isLoading,
                                ),
                                const SizedBox(height: 24),
                                _buildButton(
                                  text: "Sign In",
                                  icon: Icons.login,
                                  onTap: _handleEmailLogin,
                                  isLoading: _isLoading,
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _showEmailForm = false);
                                  },
                                  child: Text(
                                    "Back to Google sign in",
                                    style: TextStyle(
                                      color: kDeepGreen,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildButton(
      {required String text,
      required IconData icon,
      required VoidCallback onTap,
      bool isLoading = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kDeepGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kDeepGreen.withAlpha(77),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// --- 2. DASHBOARD ---
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final User? _user = FirebaseAuth.instance.currentUser;
  late Future<List<String>> _vocabCategoriesFuture;
  late Future<Map<String, dynamic>> _grammarQuizFuture;
  late String _userName;

  final Set<String> completedCategories = {};
  int completedQuizzes = 0;

  @override
  void initState() {
    super.initState();
    _vocabCategoriesFuture = _fetchVocabCategories();
    _grammarQuizFuture = _fetchGrammarQuiz();
    _loadPersistentData();
  }

  Future<void> _loadPersistentData() async {
    final categories = await _storageService.getCompletedCategories();
    final quizzes = await _storageService.getCompletedQuizzes();
    final userName = await _storageService.getUserName();
    
    setState(() {
      completedCategories.addAll(categories);
      completedQuizzes = quizzes;
      _userName = userName;
    });
  }

  Future<List<String>> _fetchVocabCategories() async {
    // Get categories from SQLite database
    final dbService = DatabaseService();
    return dbService.getCategories();
  }

  Future<Map<String, dynamic>> _fetchGrammarQuiz() {
    // Return sample grammar quiz data
    return Future.value(sampleGrammarQuiz);
  }

  void _markComplete(String category) {
    setState(() {
      completedCategories.add(category);
    });
    _storageService.saveCompletedCategories(completedCategories);
    _storageService.addHistoryEntry('vocab', category);
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'travel':
        return Icons.card_travel;
      case 'noun':
        return Icons.lightbulb_outline;
      case 'kitchen':
        return Icons.kitchen;
      default:
        return Icons.menu_book;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Halo, ${_userName.split(' ')[0]}",
                style: const TextStyle(
                    color: kTextDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text("Dashboard",
                style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    letterSpacing: 1.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.grey),
            onPressed: _showProfileBottomSheet,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Grammar Mastery",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _grammarQuizFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerGrammarCard();
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                return _buildGrammarCard(context);
              },
            ),
            const SizedBox(height: 32),
            const Text("Vocabulary Sets",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            FutureBuilder<List<String>>(
              future: _vocabCategoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerGrid();
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No vocabulary sets found.'));
                }
                final categories = snapshot.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    String key = categories[index];
                    return _buildVocabCard(
                        context, key, completedCategories.contains(key));
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            const Text("Practice Exercises",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPracticeCard(
                    context,
                    'Meaning Match',
                    Icons.checklist,
                    Colors.orange,
                    () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MeaningMatchPage()),
                      );
                      if (result is Map &&
                          result['completed'] == true &&
                          mounted) {
                        setState(() {
                          completedQuizzes++;
                        });
                        _storageService.saveCompletedQuizzes(completedQuizzes);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPracticeCard(
                    context,
                    'Synonym Match',
                    Icons.link,
                    Colors.purple,
                    () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SynonymMatchPage()),
                      );
                      if (result is Map &&
                          result['completed'] == true &&
                          mounted) {
                        setState(() {
                          completedQuizzes++;
                        });
                        _storageService.saveCompletedQuizzes(completedQuizzes);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '10 Questions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrammarCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildGrammarCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GrammarQuizPage()));
        if (result is Map && result['completed'] == true && mounted) {
          setState(() {
            completedQuizzes++;
          });
          _storageService.saveCompletedQuizzes(completedQuizzes);
          final scorePercent = result['score'] ?? 0;
          _storageService.addHistoryEntry('quiz', 'Grammar Quiz', '$scorePercent%');
        }
      },
      child: Container(
        height: 160,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kDeepGreen,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kDeepGreen.withAlpha(77),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Daily Quiz",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("10 Quick Questions",
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVocabCard(BuildContext context, String title, bool isCompleted) {
    final categoryIcon = _getIconForCategory(title);
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VocabPlayerPage(category: title)),
        );
        if (result == true) {
          _markComplete(title);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                bottom: -20,
                right: -20,
                child: Icon(
                  categoryIcon,
                  size: 100,
                  color: kSoftCream.withAlpha(200),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kSoftCream,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(categoryIcon, size: 18, color: kDeepGreen),
                      ),
                      if (isCompleted)
                        const Icon(Icons.check_circle,
                            size: 18, color: kSageGreen),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title[0].toUpperCase() + title.substring(1),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text("10 Words",
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileBottomSheet() {
    final TextEditingController nameController = TextEditingController(text: _userName);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // User Avatar & Name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: kSageGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _user?.email ?? 'user@example.com',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Edit Name
              const Text(
                'Nama Lengkap',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                onChanged: (value) {
                  // Auto-save as user types
                  _storageService.saveUserName(value);
                  setState(() => _userName = value);
                },
                decoration: InputDecoration(
                  hintText: 'Masukkan nama anda',
                  filled: true,
                  fillColor: kBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress Belajar',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.book, color: kSageGreen, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              '${completedCategories.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Vocab Selesai',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.quiz, color: kDeepGreen, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              '$completedQuizzes',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Quiz Selesai',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // History Section
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryPage(storageService: _storageService),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, color: kSageGreen),
                          const SizedBox(width: 12),
                          const Text(
                            'Riwayat Belajar',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _logout();
                  },
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }
}

// --- ANIMATED BUBBLE BACKGROUNDS ---
class AnimatedBubblesBackground extends StatefulWidget {
  final List<Color> colors;
  final bool isQuiz;
  const AnimatedBubblesBackground({
    super.key,
    required this.colors,
    this.isQuiz = false,
  });

  @override
  State<AnimatedBubblesBackground> createState() =>
      _AnimatedBubblesBackgroundState();
}

class _AnimatedBubblesBackgroundState extends State<AnimatedBubblesBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.isQuiz ? 6 : 5,
      (index) => AnimationController(
        duration: Duration(seconds: 8 + (index * 2)),
        vsync: this,
      )..repeat(reverse: true),
    );

    _animations = _controllers
        .asMap()
        .entries
        .map((e) {
          int index = e.key;
          final startOffset = Offset(
            (index * 0.25) - 0.5,
            index.isEven ? -1.0 : 1.0,
          );
          final endOffset = Offset(
            startOffset.dx + (index.isEven ? 0.3 : -0.3),
            startOffset.dy * -1,
          );
          return Tween<Offset>(begin: startOffset, end: endOffset).animate(
            CurvedAnimation(parent: e.value, curve: Curves.easeInOut),
          );
        })
        .toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kBackground,
                kSoftCream.withAlpha(153),
              ],
            ),
          ),
        ),
        // Animated bubbles
        ..._animations.asMap().entries.map((e) {
          int index = e.key;
          final animation = e.value;
          final color = widget.colors[index % widget.colors.length];
          final size = 80.0 + (index * 20);

          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Positioned(
                left: (MediaQuery.of(context).size.width * (0.5 + animation.value.dx)),
                top: (MediaQuery.of(context).size.height * (0.5 + animation.value.dy)),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withAlpha(31),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(51),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

// --- 3. VOCAB PLAYER ---
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
      // Map database results to match the expected format
      return words.map((w) => {
        'word': w['word'],
        'pronounce': w['pronounce'],
        'desc': w['description'],
      }).toList();
    }
    throw Exception('Words not found for this category.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBubblesBackground(
            colors: [kSageGreen, kDeepGreen, kSoftCream, Colors.cyan, Colors.teal],
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: true,
              title: Text(widget.category.toUpperCase(),
                  style: const TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.grey)),
            ),
            body: FutureBuilder<List<Map<String, dynamic>>>(
              future: _wordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildPlayerShimmer();
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No words found."));
                }
                return VocabPlayerView(words: snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
                Container(height: 6, width: 100, color: Colors.white),
                Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
              ],
            ),
          )
        ],
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
      // Celebratory chime sound
      await _audioPlayer.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2960/2960-preview.mp3'),
      );
    } catch (e) {
      // Silent fail if sound not found
    }
  }

  void _nextCard() {
    if (currentIndex < widget.words.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      _confettiController.play();
      _playSuccessSound();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    }
  }

  void _prevCard() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
              );
            },
            child: Center(
              key: ValueKey<int>(currentIndex),
              child: FlippableCard(
                word: Map<String, String>.from(widget.words[currentIndex]),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: currentIndex == 0 ? null : _prevCard,
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(16)),
              ),
              Container(
                height: 6,
                width: 100,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (currentIndex + 1) / widget.words.length,
                  child: Container(
                      decoration: BoxDecoration(
                          color: kSageGreen,
                          borderRadius: BorderRadius.circular(3))),
                ),
              ),
              IconButton(
                onPressed: _nextCard,
                icon: Icon(
                    currentIndex == widget.words.length - 1
                        ? Icons.check
                        : Icons.arrow_forward,
                    color: Colors.white),
                style: IconButton.styleFrom(
                    backgroundColor: kDeepGreen,
                    padding: const EdgeInsets.all(16)),
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
            maxBlastForce: 36,
            minBlastForce: 8,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [
              kSageGreen,
              kDeepGreen,
              Colors.cyan,
              Colors.teal,
              Colors.amber,
            ],
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

class _FlippableCardState extends State<FlippableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool showBack = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (showBack) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      showBack = !showBack;
    });
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
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardBack(widget.word),
                  )
                : _buildCardFront(widget.word),
          );
        },
      ),
    );
  }

  Widget _buildCardFront(Map<String, String> word) {
    return Container(
      width: 300,
      height: 400,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kSageGreen,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Spacer(),
          Text(word['word']!,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 10, color: Colors.black26)
                  ])),
          const SizedBox(height: 20),
          Text("Tap to reveal",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCardBack(Map<String, String> word) {
    return Container(
      width: 300,
      height: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: kDeepGreen,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: kDeepGreen.withAlpha(77),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(word['word']!,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kSoftCream)),
          const SizedBox(height: 8),
          Text(word['pronounce']!,
              style: TextStyle(
                  fontSize: 14,
                  color: kSoftCream.withAlpha(153),
                  fontFamily: 'Courier')),
          const SizedBox(height: 32),
          Text('"${word['desc']!}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, color: Colors.white, height: 1.5)),
        ],
      ),
    );
  }
}

// --- 4. GRAMMAR QUIZ ---
class GrammarQuizPage extends StatefulWidget {
  const GrammarQuizPage({super.key});

  @override
  State<GrammarQuizPage> createState() => _GrammarQuizPageState();
}

class _GrammarQuizPageState extends State<GrammarQuizPage> {
  late Future<List<Map<String, dynamic>>> _questionsFuture;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _fetchQuestions();
  }

  Future<List<Map<String, dynamic>>> _fetchQuestions() async {
    final allQuestions = sampleGrammarQuiz['questions'] as List<dynamic>;
    final shuffled = [...allQuestions]..shuffle(Random());
    final randomTen = shuffled.take(10).toList();
    return randomTen.map((q) => Map<String, dynamic>.from(q as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBubblesBackground(
            colors: [kDeepGreen, kSageGreen, Colors.amber, Colors.orange, Colors.lime],
            isQuiz: true,
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              elevation: 0,
              leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context)),
              title: const Text("Grammar Quiz",
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              centerTitle: true,
            ),
            body: FutureBuilder<List<Map<String, dynamic>>>(
              future: _questionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildQuizShimmer();
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error loading quiz: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No questions found."));
                }
                return GrammarQuizView(questions: snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: double.infinity, height: 72.0, color: Colors.white),
            const SizedBox(height: 40),
            ...List.generate(
                4,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                          width: double.infinity,
                          height: 80.0,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16))),
                    )),
          ],
        ),
      ),
    );
  }
}

class GrammarQuizView extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  const GrammarQuizView({super.key, required this.questions});

  @override
  State<GrammarQuizView> createState() => _GrammarQuizViewState();
}

class _GrammarQuizViewState extends State<GrammarQuizView> {
  int currentQ = 0;
  int score = 0;
  int? selectedOption;
  bool isFinished = false;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playErrorSound() async {
    try {
      // Error buzzer sound
      await _audioPlayer.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2956/2956-preview.mp3'),
      );
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _playCorrectSound() async {
    try {
      // Cheerful success sound
      await _audioPlayer.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2960/2960-preview.mp3'),
      );
    } catch (e) {
      // Silent fail
    }
  }

  void _triggerWrongFeedback() {
    HapticFeedback.vibrate();
    _playErrorSound();
  }

  void _answer(int index) {
    if (selectedOption != null) return;
    
    final isCorrect = index == widget.questions[currentQ]['correctIndex'];
    
    setState(() {
      selectedOption = index;
      if (isCorrect) {
        score++;
        _playCorrectSound();
      } else {
        _triggerWrongFeedback();
      }
    });
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (currentQ < widget.questions.length - 1) {
        setState(() {
          currentQ++;
          selectedOption = null;
        });
      } else {
        setState(() {
          isFinished = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isFinished) {
      return Stack(
        children: [
          AnimatedBubblesBackground(
            colors: [kDeepGreen, kSageGreen, Colors.amber, Colors.orange, Colors.lime],
            isQuiz: true,
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.psychology, size: 64, color: kSageGreen),
                const SizedBox(height: 24),
                const Text("Quiz Complete!",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("$score / ${widget.questions.length}",
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.w300)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDeepGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      final scorePercent = ((score / widget.questions.length) * 100).toInt();
                      Navigator.pop(context, {'completed': true, 'score': scorePercent});
                    },
                    child: const Text("Back to Dashboard"),
                  ),
                )
              ],
            ),
          ),
            ),
          ),
        ],
      );
    }
    final qData = widget.questions[currentQ];
    final options = qData['options'] as List<Map<String, dynamic>>;
    return Column(
      children: [
        LinearProgressIndicator(
          value: (currentQ + 1) / widget.questions.length,
          backgroundColor: kBackground,
          valueColor: const AlwaysStoppedAnimation<Color>(kSageGreen),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  qData['question'],
                  style: const TextStyle(
                      fontSize: 24, height: 1.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 40),
                ...List.generate(options.length, (index) {
                  final opt = options[index];
                  bool isSelected = selectedOption == index;
                  bool isCorrect = index == qData['correctIndex'];
                  bool showResult = selectedOption != null;
                  Color bgColor = kBackground;
                  Color borderColor = Colors.transparent;
                  Color textColor = kTextDark;
                  if (showResult) {
                    if (isCorrect) {
                      bgColor = const Color(0xFFD8E6D6);
                      borderColor = kSageGreen;
                      textColor = Colors.black;
                    } else if (isSelected) {
                      bgColor = Colors.red.shade50;
                      borderColor = Colors.red.shade200;
                      textColor = Colors.red.shade800;
                    } else {
                      textColor = Colors.grey.shade400;
                    }
                  }
                  return GestureDetector(
                    onTap: () => _answer(index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border.all(color: borderColor, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(opt['text']!,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: textColor)),
                                if (!showResult || isSelected || isCorrect)
                                  Text(opt['desc']!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: textColor.withAlpha(179),
                                          height: 1.5)),
                              ],
                            ),
                          ),
                          if (showResult && isCorrect)
                            const Icon(Icons.check_circle,
                                color: kSageGreen),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        )
      ],
    );
  }
}

// --- 4. MEANING MATCH PRACTICE ---
class MeaningMatchPage extends StatefulWidget {
  const MeaningMatchPage({super.key});

  @override
  State<MeaningMatchPage> createState() => _MeaningMatchPageState();
}

class _MeaningMatchPageState extends State<MeaningMatchPage> {
  final StorageService _storageService = StorageService();
  late Future<List<Map<String, dynamic>>> _questionsFuture;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _questionsFuture = _fetchQuestions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchQuestions() async {
    final allQuestions = sampleMeaningMatch['questions'] as List<dynamic>;
    final shuffled = [...allQuestions]..shuffle(Random());
    final randomTen = shuffled.take(10).toList();
    return randomTen.map((q) => Map<String, dynamic>.from(q as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _questionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Meaning Match')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        final questions = snapshot.data ?? [];
        return MeaningMatchView(
          questions: questions,
          audioPlayer: _audioPlayer,
          storageService: _storageService,
        );
      },
    );
  }
}

class MeaningMatchView extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final AudioPlayer audioPlayer;
  final StorageService storageService;

  const MeaningMatchView({
    super.key,
    required this.questions,
    required this.audioPlayer,
    required this.storageService,
  });

  @override
  State<MeaningMatchView> createState() => _MeaningMatchViewState();
}

class _MeaningMatchViewState extends State<MeaningMatchView> {
  int currentQ = 0;
  int score = 0;
  int? selectedOption;
  bool isFinished = false;

  Future<void> _playCorrectSound() async {
    try {
      await widget.audioPlayer.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'),
      );
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _playErrorSound() async {
    try {
      await widget.audioPlayer.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2956/2956-preview.mp3'),
      );
    } catch (e) {
      // Silent fail
    }
  }

  void _triggerWrongFeedback() {
    HapticFeedback.vibrate();
    _playErrorSound();
  }

  void _answer(int index) {
    if (selectedOption != null) return;

    final isCorrect = index == widget.questions[currentQ]['correctIndex'];

    setState(() {
      selectedOption = index;
      if (isCorrect) {
        score++;
        _playCorrectSound();
      } else {
        _triggerWrongFeedback();
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (currentQ < widget.questions.length - 1) {
        setState(() {
          currentQ++;
          selectedOption = null;
        });
      } else {
        setState(() {
          isFinished = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isFinished) {
      final scorePercent = ((score / widget.questions.length) * 100).toStringAsFixed(0);
      widget.storageService.addHistoryEntry('practice', 'Meaning Match', '$scorePercent%');
      return Scaffold(
        body: Stack(
          children: [
            AnimatedBubblesBackground(
              colors: [kSageGreen, kDeepGreen, kSoftCream, Colors.orange, Colors.amber],
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(51),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Great Job!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: kSageGreen,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '$scorePercent%',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: kDeepGreen,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$score/${widget.questions.length} Correct',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, {
                                'completed': true,
                                'score': scorePercent,
                              }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kSageGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Back to Dashboard',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final question = widget.questions[currentQ];
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBubblesBackground(
            colors: [kSageGreen, kDeepGreen, kSoftCream, Colors.orange, Colors.amber],
          ),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: kTextDark),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Meaning Match ${currentQ + 1}/${widget.questions.length}',
                  style: const TextStyle(color: kTextDark),
                ),
                centerTitle: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(51),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'What is the meaning of:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              question['question'],
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: kDeepGreen,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ...List.generate(
                        4,
                        (index) {
                          final isSelected = selectedOption == index;
                          final isCorrect = index == question['correctIndex'];
                          final showResult = selectedOption != null;

                          Color bgColor = Colors.white;
                          Color borderColor = Colors.grey.shade200;
                          Color textColor = kTextDark;

                          if (showResult) {
                            if (isCorrect) {
                              bgColor = Colors.green.shade50;
                              borderColor = Colors.green.shade300;
                              textColor = Colors.green.shade800;
                            } else if (isSelected && !isCorrect) {
                              bgColor = Colors.red.shade50;
                              borderColor = Colors.red.shade300;
                              textColor = Colors.red.shade800;
                            }
                          } else if (isSelected) {
                            bgColor = kSageGreen.withAlpha(31);
                            borderColor = kSageGreen;
                          }

                          return GestureDetector(
                            onTap: selectedOption == null
                                ? () => _answer(index)
                                : null,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border.all(color: borderColor, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      question['options'][index],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (showResult && isCorrect)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green)
                                  else if (showResult && isSelected && !isCorrect)
                                    const Icon(Icons.cancel, color: Colors.red),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 4B. SYNONYM MATCH PRACTICE ---
class SynonymMatchPage extends StatefulWidget {
  const SynonymMatchPage({super.key});

  @override
  State<SynonymMatchPage> createState() => _SynonymMatchPageState();
}

class _SynonymMatchPageState extends State<SynonymMatchPage> {
  final StorageService _storageService = StorageService();
  late Future<List<Map<String, dynamic>>> _questionsFuture;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _questionsFuture = _fetchQuestions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchQuestions() async {
    final allQuestions = sampleSynonymMatch['questions'] as List<dynamic>;
    final shuffled = [...allQuestions]..shuffle(Random());
    final randomTen = shuffled.take(10).toList();
    return randomTen.map((q) => Map<String, dynamic>.from(q as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _questionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Synonym Match')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        final questions = snapshot.data ?? [];
        return SynonymMatchView(
          questions: questions,
          audioPlayer: _audioPlayer,
          storageService: _storageService,
        );
      },
    );
  }
}

class SynonymMatchView extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final AudioPlayer audioPlayer;
  final StorageService storageService;

  const SynonymMatchView({
    super.key,
    required this.questions,
    required this.audioPlayer,
    required this.storageService,
  });

  @override
  State<SynonymMatchView> createState() => _SynonymMatchViewState();
}

class _SynonymMatchViewState extends State<SynonymMatchView> {
  int currentQ = 0;
  int score = 0;
  int? selectedOption;
  bool isFinished = false;

  Future<void> _playCorrectSound() async {
    try {
      await widget.audioPlayer.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'),
      );
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _playErrorSound() async {
    try {
      await widget.audioPlayer.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2956/2956-preview.mp3'),
      );
    } catch (e) {
      // Silent fail
    }
  }

  void _triggerWrongFeedback() {
    HapticFeedback.vibrate();
    _playErrorSound();
  }

  void _answer(int index) {
    if (selectedOption != null) return;

    final isCorrect = index == widget.questions[currentQ]['correctIndex'];

    setState(() {
      selectedOption = index;
      if (isCorrect) {
        score++;
        _playCorrectSound();
      } else {
        _triggerWrongFeedback();
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (currentQ < widget.questions.length - 1) {
        setState(() {
          currentQ++;
          selectedOption = null;
        });
      } else {
        setState(() {
          isFinished = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isFinished) {
      final scorePercent = ((score / widget.questions.length) * 100).toStringAsFixed(0);
      widget.storageService.addHistoryEntry('practice', 'Synonym Match', '$scorePercent%');
      return Scaffold(
        body: Stack(
          children: [
            AnimatedBubblesBackground(
              colors: [kSageGreen, kDeepGreen, kSoftCream, Colors.purple, Colors.deepPurple],
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(51),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Excellent!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: kSageGreen,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '$scorePercent%',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: kDeepGreen,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$score/${widget.questions.length} Correct',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, {
                                'completed': true,
                                'score': scorePercent,
                              }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kSageGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Back to Dashboard',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final question = widget.questions[currentQ];
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBubblesBackground(
            colors: [kSageGreen, kDeepGreen, kSoftCream, Colors.purple, Colors.deepPurple],
          ),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: kTextDark),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Synonym Match ${currentQ + 1}/${widget.questions.length}',
                  style: const TextStyle(color: kTextDark),
                ),
                centerTitle: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(51),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Find a similar word:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              question['question'],
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: kDeepGreen,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ...List.generate(
                        4,
                        (index) {
                          final isSelected = selectedOption == index;
                          final isCorrect = index == question['correctIndex'];
                          final showResult = selectedOption != null;

                          Color bgColor = Colors.white;
                          Color borderColor = Colors.grey.shade200;
                          Color textColor = kTextDark;

                          if (showResult) {
                            if (isCorrect) {
                              bgColor = Colors.green.shade50;
                              borderColor = Colors.green.shade300;
                              textColor = Colors.green.shade800;
                            } else if (isSelected && !isCorrect) {
                              bgColor = Colors.red.shade50;
                              borderColor = Colors.red.shade300;
                              textColor = Colors.red.shade800;
                            }
                          } else if (isSelected) {
                            bgColor = kSageGreen.withAlpha(31);
                            borderColor = kSageGreen;
                          }

                          return GestureDetector(
                            onTap: selectedOption == null
                                ? () => _answer(index)
                                : null,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border.all(color: borderColor, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      question['options'][index],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (showResult && isCorrect)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green)
                                  else if (showResult && isSelected && !isCorrect)
                                    const Icon(Icons.cancel, color: Colors.red),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 5. HISTORY PAGE ---
class HistoryPage extends StatefulWidget {
  final StorageService storageService;
  const HistoryPage({super.key, required this.storageService});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = widget.storageService.getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Belajar',
          style: TextStyle(color: kTextDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final history = snapshot.data ?? [];
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat belajar',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final isVocab = item['type'] == 'vocab';
              final timestamp = item['timestamp'] as DateTime;
              final formattedDate =
                  '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isVocab ? kSageGreen : kDeepGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isVocab ? Icons.book : Icons.quiz,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isVocab ? 'Vocabulary Completed' : 'Quiz Completed',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item['score'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kSageGreen.withAlpha(31),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${item['score']}',
                          style: const TextStyle(
                            color: kSageGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.check_circle,
                        color: kSageGreen,
                        size: 20,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
