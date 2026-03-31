import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MangaIPApp());

class MangaIPApp extends StatelessWidget {
  const MangaIPApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: Colors.blueAccent,
      ),
      home: const IPConnectScreen(),
    );
  }
}

class IPConnectScreen extends StatefulWidget {
  const IPConnectScreen({super.key});
  @override
  State<IPConnectScreen> createState() => _IPConnectScreenState();
}

class _IPConnectScreenState extends State<IPConnectScreen> {
  final _ipController = TextEditingController(text: "192.168.1.");

  void _connect() {
    String url = _ipController.text.trim();
    if (!url.startsWith('http')) url = 'http://$url';
    
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => MangaBrowser(baseUrl: url),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lan, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              Text("DIRECT IP ACCESS", style: GoogleFonts.bebasNeue(fontSize: 35)),
              const SizedBox(height: 40),
              TextField(
                controller: _ipController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "Nhập IP PC (VD: 192.168.1.15)",
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 55)),
                onPressed: _connect,
                child: const Text("KẾT NỐI TRỰC TIẾP"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MangaBrowser extends StatelessWidget {
  final String baseUrl;
  const MangaBrowser({super.key, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    // Trong bản này, mình giả định bạn đã có danh sách các tập truyện (folder)
    // Tín có thể nhập trực tiếp tên tập hoặc quét từ server
    return Scaffold(
      appBar: AppBar(title: const Text("THƯ VIỆN")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.folder, color: Colors.amber),
            title: const Text("Tập 01"),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => ReaderPage(folderUrl: "$baseUrl/Tap01/"),
            )),
          ),
        ],
      ),
    );
  }
}

class ReaderPage extends StatelessWidget {
  final String folderUrl;
  const ReaderPage({super.key, required this.folderUrl});

  // Giả sử ảnh trên máy tính được đặt tên là 1.jpg, 2.jpg...
  List<String> _generateImageList() {
    return List.generate(50, (index) => "$folderUrl${index + 1}.jpg");
  }

  @override
  Widget build(BuildContext context) {
    final images = _generateImageList();
    return Scaffold(
      backgroundColor: Colors.black,
      body: PhotoViewGallery.builder(
        itemCount: images.length,
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider: NetworkImage(images[index]),
          initialScale: PhotoViewComputedScale.contained,
        ),
        scrollDirection: Axis.vertical,
      ),
    );
  }
}