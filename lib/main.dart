import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

void main() => runApp(const MangaStudioV8());

class MangaStudioV8 extends StatelessWidget {
  const MangaStudioV8({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1014),
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
  final _ipController = TextEditingController(text: "192.168.1.");

  void _connect() {
    if (_ipController.text.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => MangaBrowser(ip: _ipController.text),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_sync, size: 100, color: Colors.orangeAccent),
            const SizedBox(height: 20),
            Text("MANGA CLOUD", style: GoogleFonts.bebasNeue(fontSize: 40, letterSpacing: 4)),
            const SizedBox(height: 40),
            TextField(
              controller: _ipController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Nhập IP PC (VD: 192.168.1.5:8080)",
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _connect,
              child: const Text("KẾT NỐI HFS PC", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class MangaBrowser extends StatefulWidget {
  final String ip;
  const MangaBrowser({super.key, required this.ip});
  @override
  State<MangaBrowser> createState() => _MangaBrowserState();
}

class _MangaBrowserState extends State<MangaBrowser> {
  List<String> _folders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFolders();
  }

  Future<void> _fetchFolders() async {
    try {
      final url = widget.ip.startsWith('http') ? widget.ip : 'http://${widget.ip}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var document = parse(response.body);
        var links = document.querySelectorAll('a');
        setState(() {
          _folders = links
              .map((link) => link.attributes['href'] ?? "")
              .where((s) => s.isNotEmpty && s != "/" && !s.contains("?"))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không tìm thấy Server PC!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("THƯ MỤC TRUYỆN"), backgroundColor: Colors.transparent),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
        : ListView.separated(
            padding: const EdgeInsets.all(15),
            itemCount: _folders.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.folder, color: Colors.orangeAccent),
              title: Text(_folders[index].replaceAll("/", ""), style: const TextStyle(fontSize: 16)),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => ReaderPage(ip: widget.ip, folder: _folders[index]),
              )),
            ),
          ),
    );
  }
}

class ReaderPage extends StatefulWidget {
  final String ip, folder;
  const ReaderPage({super.key, required this.ip, required this.folder});
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  int _current = 1;

  Future<List<String>> _getImages() async {
    final baseUrl = widget.ip.startsWith('http') ? widget.ip : 'http://${widget.ip}';
    final response = await http.get(Uri.parse('$baseUrl/${widget.folder}'));
    var document = parse(response.body);
    var links = document.querySelectorAll('a');
    return links
        .map((link) => link.attributes['href'] ?? "")
        .where((s) => s.toLowerCase().endsWith('.jpg') || s.toLowerCase().endsWith('.png'))
        .map((s) => '$baseUrl/${widget.folder}$s')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: Text("${widget.folder.replaceAll("/", "")} ($_current)"),
      ),
      body: FutureBuilder<List<String>>(
        future: _getImages(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return PhotoViewGallery.builder(
            itemCount: snapshot.data!.length,
            onPageChanged: (index) => setState(() => _current = index + 1),
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