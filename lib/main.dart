import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

void main() {
  runApp(const MangaApp());
}

class MangaApp extends StatelessWidget {
  const MangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manga Reader',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepOrange,
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
      appBar: AppBar(title: const Text('Truyện Tranh Offline')),
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MangaReaderScreen()),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hiển thị ảnh bìa từ thư mục assets
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/chapters/chap1/1.jpg',
                  width: 200,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              const Text('Nhấn để đọc Chapter 1', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

class MangaReaderScreen extends StatelessWidget {
  const MangaReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Tín hãy liệt kê tên các file ảnh đã bỏ vào thư mục chap1 ở đây
    final List<String> pages = [
      'assets/chapters/chap1/1.jpg',
      'assets/chapters/chap1/2.jpg',
      'assets/chapters/chap1/3.jpg',
      // Thêm tiếp các file 4.jpg, 5.jpg... nếu có
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Chapter 1'),
      ),
      body: PhotoViewGallery.builder(
        itemCount: pages.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: AssetImage(pages[index]), // Đọc ảnh Offline
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        scrollDirection: Axis.vertical, // Cuộn dọc giống đọc trên web
        loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}