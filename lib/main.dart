import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:archive/archive.dart';
import 'dart:typed_data';

void main() => runApp(const MangaStudioV23());

class MangaStudioV23 extends StatelessWidget {
  const MangaStudioV23({super.key});
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
  // IP lấy từ cấu hình HFS của bạn
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
              const Icon(Icons.cloud_download, size: 80, color: Colors.amberAccent),
              const SizedBox(height: 20),
              Text("MANGA READER V23", style: GoogleFonts.bebasNeue(fontSize: 32, letterSpacing: 2)),
              const SizedBox(height: 40),
              TextField(
                controller: _ipController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  hintText: "Nhập IP:Port",
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, minimumSize: const Size(double.infinity, 55)),
                onPressed: _connect,
                child: const Text("KẾT NỐI HFS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          
          // Bộ lọc V23: Bỏ qua các link hệ thống và icon của HFS
          if (href.isNotEmpty && 
              href != "/" && 
              !href.startsWith("?") && 
              !href.contains("sort=") &&
              name.toLowerCase() != "parent directory" &&
              !name.contains("[") ) {
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
      appBar: AppBar(title: const Text("DANH SÁCH TRUYỆN")),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : _items.isEmpty 
          ? const Center(child: Text("Không thấy file! Kiểm tra lại HFS trên PC."))
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  String path = _items[index]['href']!;
                  String name = _items[index]['name']!;
                  bool isArchive = path.toLowerCase().endsWith(".cbz") || path.toLowerCase().endsWith(".zip");
                  
                  return ListTile(
                    leading: Icon(isArchive ? Icons.menu_book : Icons.folder, color: Colors.amberAccent),
                    title: Text(Uri.decodeComponent(name)),
                    onTap: () {
                      String nextUrl = path.startsWith('http') ? path : widget.baseUrl + path;
                      if (!isArchive && !path.contains(".")) {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => FolderBrowser(baseUrl: nextUrl.endsWith('/') ? nextUrl : '$nextUrl/')));
                      } else {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderPage(url: nextUrl, isArchive: isArchive)));
                      }
                    },
                  );
                },
              ),
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
        // Chỉ lấy file ảnh bên trong file nén
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: FutureBuilder<List<Uint8List>>(
        future: _loadImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), Text("\nĐang giải nén truyện...")],
            ));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Lỗi: Không tìm thấy ảnh trong file!"));
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