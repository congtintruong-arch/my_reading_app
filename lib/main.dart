import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const MangaApp());
}

class MangaApp extends StatelessWidget {
  const MangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga Reader',
      theme: ThemeData(
        brightness: Brightness.dark, // Giao diện tối giúp đọc truyện thoải mái hơn
        primarySwatch: Colors.deepOrange,
      ),
      home: const MangaHomeScreen(),
    );
  }
}

// Màn hình danh sách truyện
class MangaHomeScreen extends StatelessWidget {
  const MangaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu: Bạn có thể thay link ảnh bìa ở đây
    final List<String> mangaCovers = [
      'https://m.media-amazon.com/images/I/8125bd7m89L.jpg',
      'https://m.media-amazon.com/images/I/91SrnW8z7pL.jpg',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Truyện Tranh Của Tín')),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Hiện 2 cột
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        itemCount: mangaCovers.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MangaReaderScreen()),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: mangaCovers[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Màn hình đọc truyện (Viewer)
class MangaReaderScreen extends StatelessWidget {
  const MangaReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Danh sách link các trang truyện mẫu
    final List<String> pages = [
      'https://images.unsplash.com/photo-1618336753974-aae8e04506aa?q=80&w=1000&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1614850523296-d8c1af93d400?q=80&w=1000&auto=format&fit=crop',
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Đang đọc...'),
      ),
      body: PhotoViewGallery.builder(
        itemCount: pages.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(pages[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: index),
          );
        },
        scrollDirection: Axis.horizontal, // Vuốt ngang để sang trang
        loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}