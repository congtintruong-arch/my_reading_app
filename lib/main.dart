import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

void main() => runApp(const MangaStudioV17());

class MangaStudioV17 extends StatelessWidget {
  const MangaStudioV17({super.key});
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
  // Điền sẵn IP từ ảnh HFS của Tín để đỡ phải gõ nhiều
  final _ipController = TextEditingController(text: "192.168.100.209:8080");

  void _connect() {
    String input = _ipController.text.trim();
    if (input.isEmpty) return;
    
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.cloud_sync, size: 100, color: Colors.orangeAccent),
              const SizedBox(height: 20),
              Text("MANGA STUDIO V17", 
                style: GoogleFonts.bebasNeue(fontSize: 40, letterSpacing: 4, color: Colors.orangeAccent)),
              const SizedBox(height: 40),
              TextField(
                controller: _ipController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "Nhập IP:Port từ HFS",
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _connect,
                child: const Text("KẾT NỐI PC", 
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
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
  void initState() {
    super.initState();
    _fetch();
  }

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
          
          // Lọc các link thư mục của HFS (không lấy các link hệ thống như ?, Name, Size...)
          if (href.isNotEmpty && href != "/" && !href.contains("?") && name.toLowerCase() != "parent directory") {
            temp.add({'name': name.isEmpty ? href : name, 'href': href});
          }
        }
        setState(() { _items = temp; _loading = false; });
      }
    } catch (e) {
      setState(() => _loading = false);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DANH SÁCH TRUYỆN"), centerTitle: true),
      body: _loading 
          ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
          : _items.isEmpty 
            ? const Center(child: Text("HFS Trống! Hãy kéo Folder vào HFS trên PC."))
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _items.length,
                itemBuilder: (context, index) => Card(
                  color: Colors.white.withOpacity(0.05),
                  child: ListTile(
                    leading: const Icon(Icons.folder, color: Colors.orangeAccent),
                    title: Text(Uri.decodeComponent(_items[index]['name']!)),
                    onTap: () {
                      String folderPath = _items[index]['href']!;
                      // Đảm bảo URL folder chuẩn
                      String fullUrl = folderPath.startsWith('http') 
                          ? folderPath 
                          : widget.baseUrl + folderPath;
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => ReaderPage(folderUrl: fullUrl),
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
    var links = doc.querySelectorAll('a');
    
    return links
        .map((l) => l.attributes['href'] ?? "")
        .where((s) => s.toLowerCase().endsWith('.jpg') || 
                      s.toLowerCase().endsWith('.png') || 
                      s.toLowerCase().endsWith('.jpeg'))
        .map((s) {
          if (s.startsWith('http')) return s;
          // Xử lý ghép link ảnh chuẩn cho HFS
          String base = folderUrl.endsWith('/') ? folderUrl : '$folderUrl/';
          return base + s;
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text("ĐANG ĐỌC")),
      body: FutureBuilder<List<String>>(
        future: _getImages(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return const Center(child: Text("Thư mục này không có file ảnh!"));
          
          return PhotoViewGallery.builder(
            itemCount: snapshot.data!.length,
            builder: (context, index) => PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(snapshot.data![index]),
              initialScale: PhotoViewComputedScale.contained,
            ),
            scrollDirection: Axis.vertical, // Vuốt dọc như đọc Webtoon
          );
        },
      ),
    );
  }
}