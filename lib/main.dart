import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- DATA ---
// Data statis untuk aplikasi

const Map<String, List<Map<String, String>>> vocabData = {
  'travel': [
    {'word': "Itinerary", 'pronounce': "/īˈtinəˌrerē/", 'desc': "Rencana perjalanan yang terperinci."},
    {'word': "Accommodation", 'pronounce': "/əˌkäməˈdāSH(ə)n/", 'desc': "Tempat tinggal sementara saat bepergian."},
    {'word': "Destination", 'pronounce': "/ˌdestəˈnāSH(ə)n/", 'desc': "Tempat tujuan akhir perjalanan."},
    {'word': "Luggage", 'pronounce': "/ˈləɡij/", 'desc': "Tas dan koper berisi barang bawaan."},
    {'word': "Departure", 'pronounce': "/dəˈpärCHər/", 'desc': "Tindakan meninggalkan suatu tempat."},
    {'word': "Arrival", 'pronounce': "/əˈrīvəl/", 'desc': "Tindakan sampai di tujuan."},
    {'word': "Passport", 'pronounce': "/ˈpaspôrt/", 'desc': "Dokumen resmi untuk perjalanan internasional."},
    {'word': "Visa", 'pronounce': "/ˈvēzə/", 'desc': "Izin masuk ke negara asing."},
    {'word': "Souvenir", 'pronounce': "/ˌso͞ovəˈnir/", 'desc': "Oleh-oleh atau kenang-kenangan."},
    {'word': "Embark", 'pronounce': "/əmˈbärk/", 'desc': "Naik ke kapal atau pesawat."},
  ],
  'noun': [
    {'word': "Freedom", 'pronounce': "/ˈfrēdəm/", 'desc': "Kekuatan atau hak untuk bertindak/berbicara."},
    {'word': "Decision", 'pronounce': "/dəˈsiZHən/", 'desc': "Kesimpulan setelah pertimbangan."},
    {'word': "Knowledge", 'pronounce': "/ˈnälij/", 'desc': "Fakta atau informasi yang diketahui."},
    {'word': "Society", 'pronounce': "/səˈsīədē/", 'desc': "Sekelompok orang yang hidup bersama."},
    {'word': "Ability", 'pronounce': "/əˈbilədē/", 'desc': "Kecakapan atau keterampilan."},
  ],
  'kitchen': [
    {'word': "Spatula", 'pronounce': "/ˈspaCHələ/", 'desc': "Alat dengan bilah datar lebar."},
    {'word': "Whisk", 'pronounce': "/(h)wisk/", 'desc': "Alat untuk mengocok telur/krim."},
    {'word': "Colander", 'pronounce': "/ˈkələndər/", 'desc': "Mangkuk berlubang untuk meniriskan."},
    {'word': "Grater", 'pronounce': "/ˈɡrādər/", 'desc': "Alat memarut makanan jadi potongan kecil."},
    {'word': "Kettle", 'pronounce': "/ˈkedl/", 'desc': "Wadah logam untuk merebus air."},
  ],
};

const List<Map<String, dynamic>> grammarQuestions = [
  {
    'question': "She _____ to the market yesterday.",
    'options': [
      {'text': "Go", 'desc': "Base form (Verb 1)."},
      {'text': "Went", 'desc': "Past form (Verb 2)."},
      {'text': "Gone", 'desc': "Past Participle (Verb 3)."},
      {'text': "Going", 'desc': "Continuous form."}
    ],
    'correctIndex': 1
  },
  {
    'question': "I have _____ seen that movie.",
    'options': [
      {'text': "Already", 'desc': "Adverb for completed action."},
      {'text': "Yet", 'desc': "Used in negative sentences."},
      {'text': "Since", 'desc': "From a past time until now."},
      {'text': "Ago", 'desc': "Refers to past time."}
    ],
    'correctIndex': 0
  },
  {
    'question': "If I _____ you, I would study harder.",
    'options': [
      {'text': "Was", 'desc': "Standard past singular."},
      {'text': "Am", 'desc': "Present singular."},
      {'text': "Were", 'desc': "Subjunctive mood."},
      {'text': "Be", 'desc': "Base form."}
    ],
    'correctIndex': 2
  },
   {
    'question': "This book is _____ than that one.",
    'options': [
      {'text': "Interesting", 'desc': "Adjective base."},
      {'text': "More interesting", 'desc': "Comparative form."},
      {'text': "Most interesting", 'desc': "Superlative form."},
      {'text': "Interest", 'desc': "Noun form."}
    ],
    'correctIndex': 1
  },
];

// --- PALETTE ---
// Warna Zen
const Color kSageGreen = Color(0xFF739072);
const Color kDeepGreen = Color(0xFF3A4D39);
const Color kSoftCream = Color(0xFFECEEEC);
const Color kBackground = Color(0xFFF5F7F5);
const Color kTextDark = Color(0xFF1F2937);

void main() {
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
        // Mensimulasikan font Serif dengan Georgia atau Times jika font Google tidak ada
        fontFamily: 'Georgia', 
        colorScheme: ColorScheme.fromSeed(seedColor: kSageGreen),
      ),
      home: const LoginPage(),
    );
  }
}

// --- 1. LOGIN PAGE ---

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -50,
            right: -50,
            child: _buildBlurBlob(200, kSageGreen.withAlpha(77)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurBlob(250, kDeepGreen.withAlpha(51)),
          ),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
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
                  
                  // Glassmorphism Card imitation
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
                        Text(
                          "Mulai perjalanan bahasa Anda dengan ketenangan pikiran.",
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
                          onTap: () {
                            Navigator.pushReplacement(
                              context, 
                              MaterialPageRoute(builder: (_) => const DashboardPage())
                            );
                          },
                        ),
                      ],
                    ),
                  )
                ],
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
      // Blur effect trick without BackdropFilter for simpler performance
      child: const DecoratedBox(
        decoration: BoxDecoration(
           // In actual device, standard blur works well
        ),
      ),
    ); // Note: In pure Flutter, BackdropFilter is used over content, or ImageFilter.blur. 
       // For simplicity in this snippet, we use solid opacity circles which look nice too.
  }

  Widget _buildButton({required String text, required IconData icon, required VoidCallback onTap}) {
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
        child: Row(
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
  // Simpan progress lokal sederhana
  final Set<String> completedCategories = {};

  void _markComplete(String category) {
    setState(() {
      completedCategories.add(category);
    });
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
            Text("Halo, Learner", style: TextStyle(color: kTextDark, fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Dashboard", style: TextStyle(color: Colors.grey[400], fontSize: 12, letterSpacing: 1.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grammar Section
            const Text("Grammar Mastery", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _buildGrammarCard(context),
            
            const SizedBox(height: 32),
            
            // Vocab Section
            const Text("Vocabulary Sets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: vocabData.keys.length,
              itemBuilder: (context, index) {
                String key = vocabData.keys.elementAt(index);
                return _buildVocabCard(context, key, completedCategories.contains(key));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrammarCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GrammarQuizPage()));
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
                Text("Daily Quiz", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("10 Pertanyaan Cepat", style: TextStyle(color: Colors.white70)),
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
        child: Column(
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
                  child: Icon(Icons.menu_book, size: 18, color: kDeepGreen),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle, size: 18, color: kSageGreen),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title[0].toUpperCase() + title.substring(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text("10 Words", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ],
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

class _VocabPlayerPageState extends State<VocabPlayerPage> with SingleTickerProviderStateMixin {
  late List<Map<String, String>> words;
  int currentIndex = 0;
  bool showBack = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    words = vocabData[widget.category] ?? [];
    
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

  void _nextCard() {
    if (currentIndex < words.length - 1) {
      setState(() {
        showBack = false;
        _controller.reset();
        currentIndex++;
      });
    } else {
      // Selesai
      Navigator.pop(context, true);
    }
  }

  void _prevCard() {
    if (currentIndex > 0) {
      setState(() {
        showBack = false;
        _controller.reset();
        currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = words[currentIndex];

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
        title: Text(widget.category.toUpperCase(), style: const TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.grey)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(child: Text("${currentIndex + 1}/${words.length}", style: const TextStyle(fontFamily: 'Courier'))),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
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
                            child: _buildCardBack(word),
                          )
                        : _buildCardFront(word),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Controls
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
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                Container(
                  height: 6, 
                  width: 100, 
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (currentIndex + 1) / words.length,
                    child: Container(decoration: BoxDecoration(color: kSageGreen, borderRadius: BorderRadius.circular(3))),
                  ),
                ),
                IconButton(
                  onPressed: _nextCard,
                  icon: Icon(currentIndex == words.length - 1 ? Icons.check : Icons.arrow_forward, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: kDeepGreen,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCardFront(Map<String, String> word) {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 60, height: 4, decoration: BoxDecoration(color: kSageGreen.withAlpha(128), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 40),
          Text(word['word']!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 20),
          Text("Tap to reveal", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
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
          BoxShadow(color: kDeepGreen.withAlpha(77), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(word['word']!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kSoftCream)),
          const SizedBox(height: 8),
          Text(word['pronounce']!, style: TextStyle(fontSize: 14, color: kSoftCream.withAlpha(153), fontFamily: 'Courier')),
          const SizedBox(height: 32),
          Text('"${word['desc']!}"', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.5)),
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
  int currentQ = 0;
  int score = 0;
  int? selectedOption;
  bool isFinished = false;

  void _answer(int index) {
    if (selectedOption != null) return;
    
    setState(() {
      selectedOption = index;
      if (index == grammarQuestions[currentQ]['correctIndex']) {
        score++;
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (currentQ < grammarQuestions.length - 1) {
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
                const Text("Quiz Complete!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("$score / ${grammarQuestions.length}", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDeepGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

    final qData = grammarQuestions[currentQ];
    final options = qData['options'] as List<Map<String, String>>;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
        title: Text("Q${currentQ + 1}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (currentQ + 1) / grammarQuestions.length,
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
                    style: const TextStyle(fontSize: 24, height: 1.5, fontWeight: FontWeight.w500),
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
                        bgColor = const Color(0xFFD8E6D6); // Greenish
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
                                  Text(opt['text']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                                  if (!showResult || isSelected || isCorrect)
                                    Text(opt['desc']!, style: TextStyle(fontSize: 12, color: textColor.withAlpha(179), height: 1.5)),
                                ],
                              ),
                            ),
                            if (showResult && isCorrect)
                              const Icon(Icons.check_circle, color: kSageGreen),
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
      ),
    );
  }
}
