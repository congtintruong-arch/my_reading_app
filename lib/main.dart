import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:archive/archive.dart'; // Thư viện giải nén
import 'dart:typed_data';

void main() => runApp(const MangaStudioV19());

class MangaStudioV19 extends StatelessWidget {
  const MangaStudioV19({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF09090B),
        primaryColor: Colors.greenAccent,
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
              const Icon(Icons.unarchive, size: 80, color: Colors.greenAccent),
              const SizedBox(height: 20),
              Text("ZIP/CBZ READER V19", style: GoogleFonts.bebasNeue(fontSize: 35)),
              const SizedBox(height: 40),
              TextField(controller: _ipController, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _connect, child: const Text("KẾT NỐI")),
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
      final response = await http.get(Uri.parse(widget.baseUrl));
      var doc = parse(response.body);
      var links = doc.querySelectorAll('a');
      List<Map<String, String>> temp = [];
      for (var l in links) {
        String href = l.attributes['href'] ?? "";
        String name = l.text.trim();
        if (href.isNotEmpty && href != "/" && !href.contains("?") && name.toLowerCase() != "parent directory") {
          temp.add({'name': name, 'href': href});
        }
      }
      setState(() { _items = temp; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("KHO TRUYỆN NÉN")),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          String path = _items[index]['href']!.toLowerCase();
          bool isArchive = path.endsWith(".zip") || path.endsWith(".cbz") || path.endsWith(".cbr");
          return ListTile(
            leading: Icon(isArchive ? Icons.compressed_outlined : Icons.folder, color: Colors.greenAccent),
            title: Text(Uri.decodeComponent(_items[index]['name']!)),
            onTap: () {
              String fullUrl = widget.baseUrl + _items[index]['href']!;
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ReaderPage(url: fullUrl, isArchive: isArchive),
              ));
            },
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
      // GIẢI NÉN FILE TRỰC TIẾP TRONG RAM
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);
      List<Uint8List> images = [];
      for (final file in archive) {
        if (file.isFile && (file.name.endsWith('.jpg') || file.name.endsWith('.png'))) {
          images.add(file.content as Uint8List);
        }
      }
      return images;
    } else {
      // Nếu là folder thì xử lý kiểu cũ (tốn thêm bước request từng ảnh)
      return []; // Tín nên dùng file nén cho bản này nhé
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Uint8List>>(
        future: _loadImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), Text("\nĐang tải và giải nén...")],
            ));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Lỗi đọc file nén!"));
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