import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'dart:typed_data';

void main() => runApp(const MangaStudioV24());

class MangaStudioV24 extends StatelessWidget {
  const MangaStudioV24({super.key});
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
  // IP lấy từ Log HFS của bạn
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
              const Icon(Icons.bolt, size: 80, color: Colors.amberAccent),
              const SizedBox(height: 10),
              Text("MANGA V24", style: GoogleFonts.bebasNeue(fontSize: 40)),
              const SizedBox(height: 40),
              TextField(
                controller: _ipController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, minimumSize: const Size(double.infinity, 60)),
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
      // SỬ DỤNG JQUERY MODE ĐỂ LẤY DỮ LIỆU THÔ
      final response = await http.get(Uri.parse("${widget.baseUrl}?mode=jquery")).timeout(const Duration(seconds: 10));
      
      // Tìm tất cả các thẻ <a> có trong trang dữ liệu thô
      RegExp regExp = RegExp(r'href="([^"]+)"[^>]*>(.*?)</a>');
      Iterable<Match> matches = regExp.allMatches(response.body);
      
      List<Map<String, String>> temp = [];
      for (var m in matches) {
        String href = m.group(1) ?? "";
        // Loại bỏ mã HTML dư thừa trong tên file
        String name = m.group(2)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? "";
        
        if (href.isNotEmpty && href != "/" && !href.startsWith("?") && name != "Parent Directory") {
          temp.add({'name': name, 'href': href});
        }
      }
      setState(() { _items = temp; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("KHO TRUYỆN")),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : _items.isEmpty 
          ? const Center(child: Text("Không tìm thấy file!\nKéo file vào HFS trên PC."))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                String path = _items[index]['href']!;
                bool isArchive = path.toLowerCase().endsWith(".cbz") || path.toLowerCase().endsWith(".zip");
                return ListTile(
                  leading: Icon(isArchive ? Icons.book : Icons.folder, color: Colors.amberAccent),
                  title: Text(Uri.decodeComponent(_items[index]['name']!)),
                  onTap: () {
                    String nextUrl = path.startsWith('http') ? path : widget.baseUrl + path;
                    if (!isArchive && !path.contains(".")) {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => FolderBrowser(baseUrl: nextUrl.endsWith('/') ? nextUrl : '$nextUrl/')));
                    } else {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderPage(url: nextUrl)));
                    }
                  },
                );
              },
            ),
    );
  }
}

class ReaderPage extends StatelessWidget {
  final String url;
  const ReaderPage({super.key, required this.url});

  Future<List<Uint8List>> _loadImages() async {
    final response = await http.get(Uri.parse(url));
    final archive = ZipDecoder().decodeBytes(response.bodyBytes);
    List<Uint8List> images = [];
    for (final file in archive) {
      if (file.isFile && (file.name.toLowerCase().endsWith('.jpg') || file.name.toLowerCase().endsWith('.png'))) {
        images.add(file.content as Uint8List);
      }
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder<List<Uint8List>>(
        future: _loadImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), Text("\nĐang tải truyện (1.7GB)...")],
            ));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Lỗi đọc file!"));
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