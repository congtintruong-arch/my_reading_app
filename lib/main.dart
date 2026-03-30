import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

void main() => runApp(const MangaStudioV11());

class MangaStudioV11 extends StatelessWidget {
  const MangaStudioV11({super.key});
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
  final _ipController = TextEditingController(text: "192.168.1.");

  void _connect() async {
    String url = _ipController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) url = 'http://$url';

    // Thử ping server trước khi chuyển màn hình
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => MangaBrowser(baseUrl: url),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi kết nối: Hãy kiểm tra IP và Firewall trên PC!\n($e)")),
      );
    }
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
              const Icon(Icons.cloud_off_sharp, size: 80, color: Colors.amberAccent),
              const SizedBox(height: 20),
              Text("MANGA CLOUD V11", style: GoogleFonts.oswald(fontSize: 30, letterSpacing: 2)),
              const SizedBox(height: 40),
              TextField(
                controller: _ipController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "VD: 192.168.1.15:8080",
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  minimumSize: const Size(double.infinity, 55),
                ),
                onPressed: _connect,
                child: const Text("KIỂM TRA & KẾT NỐI", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
  List<String> _folders = [];
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
            .map((l) => l.attributes['href'] ?? "")
            .where((s) => s.isNotEmpty && s != "/" && !s.contains("?"))
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
      appBar: AppBar(title: const Text("THƯ MỤC TRUYỆN")),
      body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _folders.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.folder, color: Colors.amberAccent),
                title: Text(Uri.decodeComponent(_folders[index])),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => Reader(baseUrl: widget.baseUrl, folder: _folders[index]),
                )),
              ),
            ),
    );
  }
}

class Reader extends StatelessWidget {
  final String baseUrl, folder;
  const Reader({super.key, required this.baseUrl, required this.folder});

  Future<List<String>> _getImages() async {
    final response = await http.get(Uri.parse('$baseUrl/$folder'));
    var doc = parse(response.body);
    return doc.querySelectorAll('a')
        .map((l) => l.attributes['href'] ?? "")
        .where((s) => s.toLowerCase().endsWith('.jpg') || s.toLowerCase().endsWith('.png'))
        .map((s) => '$baseUrl/$folder$s')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("ĐANG ĐỌC")),
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