import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

void main() => runApp(const MangaStudioV13());

class MangaStudioV13 extends StatelessWidget {
  const MangaStudioV13({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0F),
        primaryColor: Colors.deepPurpleAccent,
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
    String input = _ipController.text.trim();
    if (input.isEmpty) return;
    String url = input.startsWith('http') ? input : 'http://$input';
    if (!url.endsWith('/')) url += '/';

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
              const Icon(Icons.wifi_find, size: 100, color: Colors.deepPurpleAccent),
              const SizedBox(height: 20),
              Text("MANGA V13", style: GoogleFonts.bebasNeue(fontSize: 40, letterSpacing: 5)),
              const SizedBox(height: 40),
              TextField(
                controller: _ipController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "Nhập IP:Port (Ví dụ: 192.168.1.5:8080)",
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _connect,
                child: const Text("VÀO THƯ VIỆN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MangaBrowser extends StatefulWidget {
  final String baseUrl;
  const MangaBrowser({super.key, required this.baseUrl});
  @override
  State<MangaBrowser> createState() => _MangaBrowserState();
}

class _MangaBrowserState extends State<MangaBrowser> {
  List<Map<String, String>> _folders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final response = await http.get(Uri.parse(widget.baseUrl));
      var doc = parse(response.body);
      var links = doc.querySelectorAll('a');
      setState(() {
        _folders = links
            .map((l) => {'name': l.text.trim(), 'href': l.attributes['href'] ?? ""})
            .where((m) => m['href']!.isNotEmpty && m['href'] != "/" && !m['href']!.contains("?"))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DỰ ÁN MỚI"), backgroundColor: Colors.transparent),
      body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _folders.length,
              itemBuilder: (context, index) => Card(
                color: Colors.white.withOpacity(0.05),
                child: ListTile(
                  leading: const Icon(Icons.menu_book, color: Colors.deepPurpleAccent),
                  title: Text(_folders[index]['name']!),
                  onTap: () {
                    String folderUrl = _folders[index]['href']!;
                    if (!folderUrl.startsWith('http')) folderUrl = widget.baseUrl + folderUrl;
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ReaderPage(folderUrl: folderUrl),
                    ));
                  },
                ),
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
    var doc = parse(response.body);
    return doc.querySelectorAll('a')
        .map((l) => l.attributes['href'] ?? "")
        .where((s) => s.toLowerCase().endsWith('.jpg') || s.toLowerCase().endsWith('.png') || s.toLowerCase().endsWith('.jpeg'))
        .map((s) => s.startsWith('http') ? s : (folderUrl.endsWith('/') ? folderUrl + s : '$folderUrl/$s'))
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