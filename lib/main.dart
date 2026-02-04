import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const MangaStudioApp());

class MangaStudioApp extends StatelessWidget {
  const MangaStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        primaryColor: Colors.orangeAccent,
        colorScheme: const ColorScheme.dark(primary: Colors.orangeAccent),
        textTheme: GoogleFonts.lexendTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MangaStudioHome(),
    );
  }
}

class MangaStudioHome extends StatelessWidget {
  const MangaStudioHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text('MANGA STUDIO', 
              style: GoogleFonts.bebasNeue(letterSpacing: 2, fontSize: 35)),
            actions: [
              IconButton(icon: const Icon(Icons.search, size: 28), onPressed: () {}),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("BỘ SƯU TẬP CỦA TÍN", 
                style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 15,
                childAspectRatio: 0.6,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMangaCard(context),
                childCount: 1, // Tăng lên khi có nhiều truyện
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add, color: Colors.black, size: 30),
        onPressed: () {}, // Nơi thêm logic tạo Manga mới
      ),
    );
  }

  Widget _buildMangaCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MangaReader())),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/chapters/chap1/1.jpg', fit: BoxFit.cover,
                errorBuilder: (context, e, s) => Container(color: Colors.grey[900])),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  ),
                ),
              ),
              const Positioned(
                bottom: 12, left: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CHAPTER 1', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('Hành trình bắt đầu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MangaReader extends StatefulWidget {
  const MangaReader({super.key});
  @override
  State<MangaReader> createState() => _MangaReaderState();
}

class _MangaReaderState extends State<MangaReader> {
  int currentPage = 1;
  final int totalPages = 10; // Thay đổi theo số lượng ảnh thực tế của Tín

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black26,
        elevation: 0,
        title: Text("$currentPage / $totalPages", style: const TextStyle(fontSize: 16)),
      ),
      body: PhotoViewGallery.builder(
        itemCount: totalPages,
        onPageChanged: (index) => setState(() => currentPage = index + 1),
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider: AssetImage('assets/chapters/chap1/${index + 1}.jpg'),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2.5,
        ),
        scrollDirection: Axis.vertical, // Cuộn dọc phong cách Webtoon
      ),
    );
  }
}