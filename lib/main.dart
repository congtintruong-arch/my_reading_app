import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MangaApp());

class MangaApp extends StatelessWidget {
  const MangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090909),
        primaryColor: Colors.deepOrangeAccent,
        textTheme: GoogleFonts.lexendTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MangaHomeScreen(),
    );
  }
}

class MangaHomeScreen extends StatelessWidget {
  const MangaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('MANGA HUB', 
                style: GoogleFonts.russoOne(color: Colors.white, letterSpacing: 2)),
              background: Container(color: Colors.deepOrangeAccent.withOpacity(0.1)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tiếp tục đọc", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _buildMangaCard(context, "Chapter 1", "Sự trỗi dậy của lập trình viên"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMangaCard(BuildContext context, String chapter, String title) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MangaReaderScreen())),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF000000)]),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
              child: Image.asset('assets/chapters/chap1/1.jpg', width: 140, fit: BoxFit.cover,
                errorBuilder: (context, e, s) => Container(width: 140, color: Colors.grey[900])),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                      child: Text(chapter, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2),
                    const Spacer(),
                    const Row(children: [Icon(Icons.play_circle, color: Colors.orange), SizedBox(width: 8), Text("Đọc ngay")]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MangaReaderScreen extends StatefulWidget {
  const MangaReaderScreen({super.key});
  @override
  State<MangaReaderScreen> createState() => _MangaReaderScreenState();
}

class _MangaReaderScreenState extends State<MangaReaderScreen> {
  final int totalPages = 10; 
  int currentPage = 1;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: totalPages,
            onPageChanged: (index) => setState(() => currentPage = index + 1),
            builder: (context, index) => PhotoViewGalleryPageOptions(
              imageProvider: AssetImage('assets/chapters/chap1/${index + 1}.jpg'),
              initialScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
            ),
            scrollDirection: Axis.vertical,
          ),
          // Thanh tiến trình trên cùng
          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: currentPage / totalPages,
                    backgroundColor: Colors.white10,
                    color: Colors.orange,
                    minHeight: 2,
                  ),
                ),
                const SizedBox(width: 15),
                Text("$currentPage/$totalPages", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}