import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vocab/firebase_options.dart';
import 'package:vocab/data/sample_data.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _buildBlurBlob(200, kSageGreen.withValues(alpha: 0.3)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurBlob(250, kDeepGreen.withValues(alpha: 0.2)),
          ),
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

  Widget _buildBlurBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(),
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
  final User? _user = FirebaseAuth.instance.currentUser;
  late Future<List<String>> _vocabCategoriesFuture;
  late Future<Map<String, dynamic>> _grammarQuizFuture;
  bool _isLoggingOut = false;

  final Set<String> completedCategories = {};

  @override
  void initState() {
    super.initState();
    _vocabCategoriesFuture = _fetchVocabCategories();
    _grammarQuizFuture = _fetchGrammarQuiz();
  }

  Future<List<String>> _fetchVocabCategories() async {
    // Get categories from sample data
    return sampleVocab.keys.toList();
  }

  Future<Map<String, dynamic>> _fetchGrammarQuiz() {
    // Return sample grammar quiz data
    return Future.value(sampleGrammarQuiz);
  }

  void _markComplete(String category) {
    setState(() {
      completedCategories.add(category);
    });
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
        backgroundColor: Colors.white.withAlpha(204),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Halo, ${_user?.displayName?.split(' ')[0] ?? 'Learner'}",
                style: TextStyle(
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
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout, color: Colors.grey),
            onPressed: _isLoggingOut
                ? null
                : () async {
                    setState(() => _isLoggingOut = true);
                    try {
                      await _authService.signOut();
                      // AuthWrapper will handle navigation when user becomes null
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _isLoggingOut = false);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logout failed: $e')),
                      );
                    }
                  },
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
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GrammarQuizPage()));
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
    final words = sampleVocab[category];
    if (words != null) {
      return words.map((w) => Map<String, dynamic>.from(w)).toList();
    }
    throw Exception('Words not found for this category.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoftCream,
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

  void _nextCard() {
    if (currentIndex < widget.words.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      Navigator.pop(context, true);
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
    return Column(
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
    final questions = sampleGrammarQuiz['questions'] as List<dynamic>;
    return questions.map((q) => Map<String, dynamic>.from(q as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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

  void _answer(int index) {
    if (selectedOption != null) return;
    setState(() {
      selectedOption = index;
      if (index == widget.questions[currentQ]['correctIndex']) {
        score++;
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
      return Scaffold(
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Back to Dashboard"),
                  ),
                )
              ],
            ),
          ),
        ),
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
