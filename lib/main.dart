import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:archive/archive.dart';
import 'dart:typed_data';

void main() => runApp(const MangaStudioV21());

class MangaStudioV21 extends StatelessWidget {
  const MangaStudioV21({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0F),
        primaryColor: Colors.amberAccent,
      ),
      home: const ConnectScreen(),
    );
  }
}

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  // IP và Port lấy trực tiếp từ hình HFS bạn gửi
  final _ipController = TextEditingController(text: "192.168.100.209:8080");

  void _connect() {
    String input = _ipController.text.trim();
    String url = input.startsWith('http') ? input : 'http://$input';
    if (!url.endsWith('/')) url += '/';
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => FolderBrowser(baseUrl: url),
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
              const Icon(Icons.library_books_rounded, size: 80, color: Colors.amberAccent),
              const SizedBox(height: 10),
              Text("MANGA READER V21", style: GoogleFonts.oswald(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _ipController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, minimumSize: const Size(double.infinity, 55)),
                onPressed: _connect,
                child: const Text("KẾT NỐI NGAY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FolderBrowser extends StatefulWidget {
  final String baseUrl;
  const FolderBrowser({super.key, required this.baseUrl});
  @override
  State<FolderBrowser> createState() => _FolderBrowserState();
}

class _FolderBrowserState extends State<FolderBrowser> {
  List<Map<String, String>> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    try {
      final response = await http.get(Uri.parse(widget.baseUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        var doc = parse(response.body);
        var links = doc.querySelectorAll('a');
        List<Map<String, String>> temp = [];
        
        for (var l in links) {
          String href = l.attributes['href'] ?? "";
          String name = l.text.trim();
          
          if (href.isNotEmpty && href != "/" && !href.startsWith("?") && 
              !href.contains("sort=") && name.toLowerCase() != "parent directory") {
            temp.add({'name': name.isEmpty ? href : name, 'href': href});
          }
        }
        setState(() { _items = temp; _loading = false; });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DANH SÁCH FILE")),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : _items.isEmpty 
          ? const Center(child: Text("HFS chưa có file nào!\nKéo file vào HFS trên PC nhé."))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                String path = _items[index]['href']!;
                bool isArchive = path.toLowerCase().endsWith(".cbz") || path.toLowerCase().endsWith(".zip");
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  color: Colors.white.withOpacity(0.05),
                  child: ListTile(
                    leading: Icon(isArchive ? Icons.book : Icons.folder, color: Colors.amberAccent),
                    title: Text(Uri.decodeComponent(_items[index]['name']!)),
                    onTap: () {
                      String fullUrl = path.startsWith('http') ? path : widget.baseUrl + path;
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => ReaderPage(url: fullUrl, isArchive: isArchive),
                      ));
                    },
                  ),
                );
              },
            ),
    );
  }
}

class ReaderPage extends StatelessWidget {
  final String url;
  final bool isArchive;
  const ReaderPage({super.key, required this.url, required this.isArchive});

  Future<List<Uint8List>> _loadImages() async {
    final response = await http.get(Uri.parse(url));
    if (isArchive) {
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);
      List<Uint8List> images = [];
      for (final file in archive) {
        if (file.isFile && (file.name.toLowerCase().endsWith('.jpg') || 
            file.name.toLowerCase().endsWith('.png') || 
            file.name.toLowerCase().endsWith('.jpeg'))) {
          images.add(file.content as Uint8List);
        }
      }
      return images;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: FutureBuilder<List<Uint8List>>(
        future: _loadImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Không có ảnh trong file này!"));
          }
          return PhotoViewGallery.builder(
            itemCount: snapshot.data!.length,
            builder: (context, index) => PhotoViewGalleryPageOptions(
              imageProvider: MemoryImage(snapshot.data![index]),
              initialScale: PhotoViewComputedScale.contained,
            ),
            scrollDirection: Axis.vertical,
          );
        },
      ),
    );
  }
}