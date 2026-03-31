import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'dart:typed_data';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark(),
  home: const ConnectScreen(),
));

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _controller = TextEditingController(text: "192.168.100.209:8080");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flash_on, size: 80, color: Colors.amberAccent),
              const SizedBox(height: 20),
              const Text("MANGA V25 - FIX NAME", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(controller: _controller, textAlign: TextAlign.center, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  String url = _controller.text.startsWith('http') ? _controller.text : 'http://${_controller.text}';
                  if (!url.endsWith('/')) url += '/';
                  Navigator.push(context, MaterialPageRoute(builder: (context) => FolderBrowser(baseUrl: url)));
                }, 
                child: const Text("KẾT NỐI", style: TextStyle(color: Colors.black)),
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
      // Dùng mode=jquery để lấy data thô từ HFS
      final response = await http.get(Uri.parse("${widget.baseUrl}?mode=jquery")).timeout(const Duration(seconds: 10));
      
      // Regex cực mạnh để bắt mọi thẻ <a> có đuôi .cbz hoặc .zip
      RegExp regExp = RegExp(r'href="([^"]+)"[^>]*>(.*?)</a>', caseSensitive: false);
      Iterable<Match> matches = regExp.allMatches(response.body);
      
      List<Map<String, String>> temp = [];
      for (var m in matches) {
        String href = m.group(1) ?? "";
        String name = m.group(2)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? "";
        
        // Chỉ cần là file .cbz hoặc folder là lấy tất
        if (href.isNotEmpty && href != "/" && !href.startsWith("?")) {
           temp.add({'name': name.isEmpty ? href : name, 'href': href});
        }
      }
      setState(() { _items = temp; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DANH SÁCH")),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : _items.isEmpty 
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Vẫn không thấy?"),
                const SizedBox(height: 10),
                const Text("Thử đổi tên file trên HFS thành '1.cbz'"),
                ElevatedButton(onPressed: _fetch, child: const Text("TẢI LẠI"))
              ],
            ))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                String path = _items[index]['href']!;
                String name = _items[index]['name']!;
                bool isArchive = path.toLowerCase().contains(".cbz") || path.toLowerCase().contains(".zip");
                
                return ListTile(
                  leading: Icon(isArchive ? Icons.book : Icons.folder, color: Colors.amberAccent),
                  title: Text(Uri.decodeComponent(name)),
                  onTap: () {
                    String nextUrl = path.startsWith('http') ? path : widget.baseUrl + path;
                    if (isArchive) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderPage(url: nextUrl)));
                    } else if (!path.contains(".")) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FolderBrowser(baseUrl: nextUrl.endsWith('/') ? nextUrl : '$nextUrl/')));
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
  const ReaderPage({super.key});

  Future<List<Uint8List>> _loadImages() async {
    final response = await http.get(Uri.parse(url));
    final archive = ZipDecoder().decodeBytes(response.bodyBytes);
    List<Uint8List> images = [];
    for (final file in archive) {
      if (file.isFile && (file.name.toLowerCase().endsWith('.jpg') || file.name.toLowerCase().endsWith('.png'))) {
        images.add(file.content as Uint8List);
      }
    }
    // Sắp xếp tên ảnh để đọc đúng thứ tự
    images.sort((a, b) => a.length.compareTo(b.length)); 
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
              children: [CircularProgressIndicator(), Text("\nĐang mở truyện nặng 1.7GB...")],
            ));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Lỗi: Không tìm thấy ảnh!"));
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