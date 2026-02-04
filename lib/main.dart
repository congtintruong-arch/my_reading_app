import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:convert';
import 'dart:io';

void main() => runApp(const MangaStudioV6());

class MangaStudioV6 extends StatelessWidget {
  const MangaStudioV6({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050507),
        primaryColor: Colors.cyanAccent,
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
    final String? data = prefs.getString('manga_storage_v6');
    if (data != null) {
      setState(() => _mangaList = List<Map<String, dynamic>>.from(json.decode(data)));
    }
  }

  Future<void> _saveManga() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manga_storage_v6', json.encode(_mangaList));
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      TextEditingController nameController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF121214),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 0.5)),
          title: const Text("Khởi tạo Manga mới"),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Tên tác phẩm...", hintStyle: TextStyle(color: Colors.white24)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _mangaList.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': nameController.text,
                      'imagePaths': pickedFiles.map((e) => e.path).toList(),
                      'lastPage': 0, // Lưu vị trí trang đang đọc
                    });
                  });
                  _saveManga();
                  Navigator.pop(context);
                }
              },
              child: const Text("Tạo", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _mangaList.where((m) => m['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF050507), Color(0xFF101018)]),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              expandedHeight: 140,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('MANGA STUDIO', style: GoogleFonts.syncopate(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.cyanAccent)),
                centerTitle: true,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 20)]),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: "Tìm truyện của Tín...",
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: AnimationLimiter(
                child: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.68, mainAxisSpacing: 20, crossAxisSpacing: 20),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final manga = filtered[index];
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: const Duration(milliseconds: 600),
                        columnCount: 2,
                        child: SlideAnimation(
                          verticalOffset: 50,
                          child: FadeInAnimation(child: _buildNeonCard(manga, index)),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickImages,
        backgroundColor: Colors.cyanAccent,
        icon: const Icon(Icons.auto_stories, color: Colors.black),
        label: const Text("Tạo Chapter", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildNeonCard(Map<String, dynamic> manga, int index) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderScreen(manga: manga)));
        _loadManga(); // Tải lại để cập nhật trang cuối
      },
      onLongPress: () => _deleteManga(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(manga['imagePaths'][0]), fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)]),
                ),
              ),
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(manga['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: (manga['lastPage'] + 1) / manga['imagePaths'].length,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(Colors.cyanAccent),
                      minHeight: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteManga(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa Manga này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(onPressed: () { setState(() => _mangaList.removeAt(index)); _saveManga(); Navigator.pop(context); }, child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class ReaderScreen extends StatefulWidget {
  final Map<String, dynamic> manga;
  const ReaderScreen({super.key, required this.manga});
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _controller;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.manga['lastPage'] ?? 0;
    _controller = PageController(initialPage: _currentPage);
  }

  void _updateProgress(int page) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('manga_storage_v6');
    if (data != null) {
      List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(json.decode(data));
      for (var m in list) {
        if (m['id'] == widget.manga['id']) {
          m['lastPage'] = page;
          break;
        }
      }
      await prefs.setString('manga_storage_v6', json.encode(list));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> images = List<String>.from(widget.manga['imagePaths']);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.manga['title'], style: const TextStyle(fontSize: 14)),
        actions: [Center(child: Padding(padding: const EdgeInsets.only(right: 20), child: Text("${_currentPage + 1}/${images.length}", style: const TextStyle(color: Colors.cyanAccent))))],
      ),
      body: PhotoViewGallery.builder(
        itemCount: images.length,
        pageController: _controller,
        onPageChanged: (i) {
          setState(() => _currentPage = i);
          _updateProgress(i);
        },
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider: FileImage(File(images[index])),
          initialScale: PhotoViewComputedScale.contained,
        ),
        scrollDirection: Axis.vertical,
      ),
    );
  }
}