import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:archive/archive.dart';
import 'dart:typed_data';

void main() => runApp(const MangaStudioV20());

class MangaStudioV20 extends StatelessWidget {
  const MangaStudioV20({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF09090B),
        primaryColor: Colors.orangeAccent,
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
  // IP lấy từ hình HFS của Tín
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
              const Icon(Icons.cyclone, size: 80, color: Colors.orangeAccent),
              const SizedBox(height: 20),
              Text("MANGA V20", style: GoogleFonts.bebasNeue(fontSize: 40, letterSpacing: 5)),
              const SizedBox(height: 40),
              TextField(
                controller: _ipController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  minimumSize: const Size(double.infinity, 60),
                ),
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
      appBar: AppBar(title: const Text("DANH SÁCH")),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          String path = _items[index]['href']!.toLowerCase();
          bool isFile = path.endsWith(".cbz") || path.endsWith(".zip") || path.endsWith(".jpg");
          return ListTile(
            leading: Icon(isFile ? Icons.description : Icons.folder, color: Colors.orangeAccent),
            title: Text(Uri.decodeComponent(_items[index]['name']!)),
            onTap: () {
              String fullUrl = widget.baseUrl + _items[index]['href']!;
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ReaderPage(url: fullUrl, isFile: isFile),
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
  final bool isFile;
  const ReaderPage({super.key, required this.url, required this.isFile});

  Future<List<Uint8List>> _loadImages() async {
    final response = await http.get(Uri.parse(url));
    if (url.toLowerCase().endsWith(".cbz") || url.toLowerCase().endsWith(".zip")) {
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);
      List<Uint8List> images = [];
      for (final file in archive) {
        if (file.isFile && (file.name.endsWith('.jpg') || file.name.endsWith('.png') || file.name.endsWith('.jpeg'))) {
          images.add(file.content as Uint8List);
        }
      }
      return images;
    } else if (isFile) {
      return [response.bodyBytes];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder<List<Uint8List>>(
        future: _loadImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Không đọc được file!"));
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