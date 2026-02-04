import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

void main() => runApp(const MangaStudioV4());

class MangaStudioV4 extends StatelessWidget {
  const MangaStudioV4({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: Colors.orangeAccent,
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
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadManga();
  }

  // Tải dữ liệu từ máy
  Future<void> _loadManga() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('manga_storage');
    if (data != null) {
      setState(() => _mangaList = List<Map<String, dynamic>>.from(json.decode(data)));
    }
  }

  // Lưu dữ liệu vào máy
  Future<void> _saveManga() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manga_storage', json.encode(_mangaList));
  }

  // Chọn ảnh từ điện thoại và tạo truyện mới
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    
    if (pickedFiles.isNotEmpty) {
      TextEditingController nameController = TextEditingController();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Tên bộ truyện mới"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "VD: One Piece, Naruto..."),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _mangaList.add({
                      'title': nameController.text,
                      'imagePaths': pickedFiles.map((e) => e.path).toList(),
                    });
                  });
                  _saveManga();
                  Navigator.pop(context);
                }
              },
              child: const Text("Tạo ngay"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MANGA STUDIO PRO', style: GoogleFonts.bebasNeue(fontSize: 30, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _mangaList.isEmpty 
          ? const Center(child: Text("Nhấn + để thêm truyện từ điện thoại"))
          : GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.7, mainAxisSpacing: 15, crossAxisSpacing: 15,
              ),
              itemCount: _mangaList.length,
              itemBuilder: (context, index) {
                final manga = _mangaList[index];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ReaderScreen(
                      title: manga['title'], 
                      images: List<String>.from(manga['imagePaths'])
                    ),
                  )),
                  onLongPress: () { // Nhấn giữ để xóa
                    setState(() => _mangaList.removeAt(index));
                    _saveManga();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: FileImage(File(manga['imagePaths'][0])),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                      child: Text(manga['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImages,
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add_photo_alternate, color: Colors.black),
      ),
    );
  }
}

class ReaderScreen extends StatelessWidget {
  final String title;
  final List<String> images;
  const ReaderScreen({super.key, required this.title, required this.images});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Đã thêm AppBar để có nút Back thoát ra
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black54,
      ),
      body: PhotoViewGallery.builder(
        itemCount: images.length,
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider: FileImage(File(images[index])),
          initialScale: PhotoViewComputedScale.contained,
        ),
        scrollDirection: Axis.vertical, // Cuộn dọc như Webtoon
      ),
    );
  }
}