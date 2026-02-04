import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:convert';
import 'dart:io';

void main() => runApp(const MangaStudioV5());

class MangaStudioV5 extends StatelessWidget {
  const MangaStudioV5({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF08080A),
        primaryColor: const Color(0xFFFF4D00),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _mangaList = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadManga();
  }

  Future<void> _loadManga() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('manga_storage_v5');
    if (data != null) {
      setState(() => _mangaList = List<Map<String, dynamic>>.from(json.decode(data)));
    }
  }

  Future<void> _saveManga() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manga_storage_v5', json.encode(_mangaList));
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      TextEditingController nameController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Tên Bộ Truyện"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Nhập tên truyện...", focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange))),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _mangaList.insert(0, {
                      'title': nameController.text,
                      'imagePaths': pickedFiles.map((e) => e.path).toList(),
                      'isFavorite': false,
                    });
                  });
                  _saveManga();
                  Navigator.pop(context);
                }
              },
              child: const Text("Lưu"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _mangaList.where((m) => m['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 150,
            backgroundColor: const Color(0xFF08080A),
            flexibleSpace: FlexibleSpaceBar(
              title: Text('MANGA STUDIO', style: GoogleFonts.bebasNeue(letterSpacing: 3, fontSize: 32, color: Colors.orange)),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: "Tìm kiếm truyện của Tín...",
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1D),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: AnimationLimiter(
              child: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, mainAxisSpacing: 16, crossAxisSpacing: 16),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final manga = filteredList[index];
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: _buildGlassCard(manga, index),
                        ),
                      ),
                    );
                  },
                  childCount: filteredList.length,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickImages,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text("Thêm Truyện"),
      ),
    );
  }

  Widget _buildGlassCard(Map<String, dynamic> manga, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderScreen(title: manga['title'], images: List<String>.from(manga['imagePaths'])))),
      onLongPress: () => _confirmDelete(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          image: DecorationImage(image: FileImage(File(manga['imagePaths'][0])), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)]),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(manga['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              const SizedBox(height: 4),
              Text("${manga['imagePaths'].length} trang", style: const TextStyle(color: Colors.orange, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa truyện?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(onPressed: () { setState(() => _mangaList.removeAt(index)); _saveManga(); Navigator.pop(context); }, child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class ReaderScreen extends StatefulWidget {
  final String title;
  final List<String> images;
  const ReaderScreen({super.key, required this.title, required this.images});
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  int _currentPage = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        actions: [Center(child: Padding(padding: const EdgeInsets.only(right: 20), child: Text("$_currentPage/${widget.images.length}")))],
      ),
      body: PhotoViewGallery.builder(
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentPage = i + 1),
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider: FileImage(File(widget.images[index])),
          initialScale: PhotoViewComputedScale.contained,
        ),
        scrollDirection: Axis.vertical,
      ),
    );
  }
}