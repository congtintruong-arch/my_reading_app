import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

void main() => runApp(const MangaWebDAV());

class MangaWebDAV extends StatelessWidget {
  const MangaWebDAV({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        primaryColor: Colors.cyanAccent,
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
  final _ipController = TextEditingController(text: "192.168.1.");

  void _connect() {
    String url = _ipController.text.trim();
    if (!url.startsWith('http')) url = 'http://$url';
    if (!url.endsWith('/')) url += '/';

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => FolderListScreen(baseUrl: url),
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
              const Icon(Icons.cloud_circle, size: 100, color: Colors.cyanAccent),
              const SizedBox(height: 20),
              Text("MANGA WEBDAV", style: GoogleFonts.bebasNeue(fontSize: 40, letterSpacing: 4)),
              const SizedBox(height: 40),
              TextField(
                controller: _ipController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "IP:Port (VD: 192.168.1.15:80)",
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  minimumSize: const Size(double.infinity, 60),
                ),
                onPressed: _connect,
                child: const Text("KẾT NỐI PC", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FolderListScreen extends StatefulWidget {
  final String baseUrl;
  const FolderListScreen({super.key, required this.baseUrl});
  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  List<String> _folders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFolders();
  }

  Future<void> _fetchFolders() async {
    try {
      final response = await http.get(Uri.parse(widget.baseUrl));
      if (response.statusCode == 200) {
        var document = parse(response.body);
        var links = document.querySelectorAll('a');
        setState(() {
          _folders = links
              .map((l) => l.attributes['href'] ?? "")
              .where((s) => s.isNotEmpty && s != "/" && !s.contains("?"))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối IP!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DANH SÁCH TẬP TRUYỆN")),
      body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _folders.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.folder, color: Colors.amber),
                title: Text(Uri.decodeComponent(_folders[index]).replaceAll("/", "")),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ReaderPage(folderUrl: widget.baseUrl + _folders[index]),
                )),
              ),
            ),
    );
  }
}

class ReaderPage extends StatelessWidget {
  final String folderUrl;
  const ReaderPage({super.key, required this.folderUrl});

  Future<List<String>> _getImages() async {
    final response = await http.get(Uri.parse(folderUrl));
    var document = parse(response.body);
    var links = document.querySelectorAll('a');
    return links
        .map((l) => l.attributes['href'] ?? "")
        .where((s) => s.toLowerCase().endsWith('.jpg') || s.toLowerCase().endsWith('.png'))
        .map((s) => folderUrl + s)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<String>>(
        future: _getImages(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return const Center(child: Text("Thư mục trống!"));
          return PhotoViewGallery.builder(
            itemCount: snapshot.data!.length,
            builder: (context, index) => PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(snapshot.data![index]),
              initialScale: PhotoViewComputedScale.contained,
            ),
            scrollDirection: Axis.vertical,
          );
        },
      ),
    );
  }
}