import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

void main() => runApp(const MangaStudioUltra());

class MangaStudioUltra extends StatelessWidget {
  const MangaStudioUltra({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: Colors.orangeAccent,
      ),
      home: const MangaStudioHome(),
    );
  }
}

class MangaStudioHome extends StatefulWidget {
  const MangaStudioHome({super.key});

  @override
  State<MangaStudioHome> createState() => _MangaStudioHomeState();
}

class _MangaStudioHomeState extends State<MangaStudioHome> {
  // Danh sách truyện thực tế
  List<Map<String, String>> allManga = [
    {'title': 'Chapter 1', 'subtitle': 'Hành trình bắt đầu', 'image': 'assets/chapters/chap1/1.jpg'},
  ];

  // Danh sách hiển thị sau khi lọc
  List<Map<String, String>> displayedManga = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    displayedManga = allManga; // Mặc định hiện tất cả
  }

  // Logic Tìm kiếm
  void _filterManga(String query) {
    setState(() {
      displayedManga = allManga
          .where((manga) => manga['title']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Logic Thêm Manga Mới
  void _addNewManga() {
    TextEditingController titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tạo Manga Mới"),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: "Nhập tên chương..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  allManga.add({
                    'title': titleController.text,
                    'subtitle': 'Vừa được tạo',
                    'image': 'assets/chapters/chap1/1.jpg', // Tạm dùng ảnh cũ làm bìa
                  });
                  displayedManga = allManga;
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Tạo"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            backgroundColor: const Color(0xFF151515),
            title: Text('MANGA STUDIO', style: GoogleFonts.bebasNeue(letterSpacing: 2, fontSize: 32)),
          ),
          // Thanh tìm kiếm thông minh
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterManga,
                decoration: InputDecoration(
                  hintText: "Tìm kiếm truyện...",
                  prefixIcon: const Icon(Icons.search, color: Colors.orangeAccent),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.7,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMangaCard(displayedManga[index]),
                childCount: displayedManga.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        onPressed: _addNewManga, // Gọi hàm thêm truyện
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  Widget _buildMangaCard(Map<String, String> manga) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReaderScreen())),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(image: AssetImage(manga['image']!), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(manga['title']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
              Text(manga['subtitle']!, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PhotoViewGallery.builder(
        itemCount: 10,
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider: AssetImage('assets/chapters/chap1/${index + 1}.jpg'),
          initialScale: PhotoViewComputedScale.contained,
        ),
        scrollDirection: Axis.vertical,
      ),
    );
  }
}