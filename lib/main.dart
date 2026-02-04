import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const MangaStudioUltimate());

class MangaStudioUltimate extends StatelessWidget {
  const MangaStudioUltimate({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        primaryColor: Colors.deepOrangeAccent,
        colorScheme: const ColorScheme.dark(primary: Colors.deepOrangeAccent),
      ),
      home: const MangaHomeScreen(),
    );
  }
}

class MangaHomeScreen extends StatefulWidget {
  const MangaHomeScreen({super.key});

  @override
  State<MangaHomeScreen> createState() => _MangaHomeScreenState();
}

class _MangaHomeScreenState extends State<MangaHomeScreen> {
  List<Map<String, dynamic>> _allManga = [];
  List<Map<String, dynamic>> _displayedManga = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMangaData(); // Tải dữ liệu khi vừa mở app
  }

  // Tải danh sách truyện đã lưu
  Future<void> _loadMangaData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('manga_list_key');
    if (savedData != null) {
      setState(() {
        _allManga = List<Map<String, dynamic>>.from(json.decode(savedData));
        _displayedManga = _allManga;
      });
    } else {
      // Dữ liệu mẫu nếu máy chưa có gì
      _allManga = [{'title': 'Chapter 1', 'folder': 'chap1'}];
      _displayedManga = _allManga;
    }
  }

  // Lưu danh sách truyện vào máy
  Future<void> _saveMangaData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manga_list_key', json.encode(_allManga));
  }

  // Logic Tìm kiếm
  void _onSearch(String query) {
    setState(() {
      _displayedManga = _allManga
          .where((m) => m['title'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Logic Thêm Manga Mới
  void _showAddMangaDialog() {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController folderCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tạo Manga Mới"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: "Tên truyện (VD: Conan)")),
            const SizedBox(height: 10),
            TextField(controller: folderCtrl, decoration: const InputDecoration(hintText: "Thư mục ảnh (VD: chap1)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _allManga.add({
                    'title': nameCtrl.text,
                    'folder': folderCtrl.text.isEmpty ? 'chap1' : folderCtrl.text,
                  });
                  _displayedManga = _allManga;
                });
                _saveMangaData(); // Lưu ngay để không bị mất
                Navigator.pop(context);
              }
            },
            child: const Text("Thêm"),
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
            title: Text('MANGA STUDIO', style: GoogleFonts.bebasNeue(letterSpacing: 2)),
            backgroundColor: const Color(0xFF1A1A1A),
          ),
          // Thanh tìm kiếm thông minh
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm trong bộ sưu tập...',
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
                crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.65,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMangaCard(_displayedManga[index]),
                childCount: _displayedManga.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMangaDialog,
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  Widget _buildMangaCard(Map<String, dynamic> manga) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderPage(folder: manga['folder']))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage('assets/chapters/${manga['folder']}/1.jpg'),
            fit: BoxFit.cover,
            onError: (e, s) => const Icon(Icons.broken_image),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]),
          ),
          padding: const EdgeInsets.all(12),
          child: Text(manga['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}

class ReaderPage extends StatelessWidget {
  final String folder;
  const ReaderPage({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PhotoViewGallery.builder(
        itemCount: 10, // Bạn có thể tùy chỉnh số lượng ảnh ở đây
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider: AssetImage('assets/chapters/$folder/${index + 1}.jpg'),
          initialScale: PhotoViewComputedScale.contained,
        ),
        scrollDirection: Axis.vertical,
      ),
    );
  }
}