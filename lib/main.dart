import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smb_kit/smb_kit.dart';
import 'dart:typed_data';

void main() => runApp(const MangaSMBApp());

class MangaSMBApp extends StatelessWidget {
  const MangaSMBApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        primaryColor: Colors.blueAccent,
      ),
      home: const SMBConnectScreen(),
    );
  }
}

class SMBConnectScreen extends StatefulWidget {
  const SMBConnectScreen({super.key});
  @override
  State<SMBConnectScreen> createState() => _SMBConnectScreenState();
}

class _SMBConnectScreenState extends State<SMBConnectScreen> {
  final _ipController = TextEditingController(text: "192.168.1.");
  final _userController = TextEditingController(text: "admin");
  final _passController = TextEditingController();
  final _shareNameController = TextEditingController(text: "Manga"); // Tên thư mục bạn bấm Share trên Windows

  void _connect() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => MangaListScreen(
        ip: _ipController.text,
        user: _userController.text,
        pass: _passController.text,
        share: _shareNameController.text,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("KẾT NỐI PC (SMB)", style: GoogleFonts.bebasNeue())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(Icons.dns, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            _input(_ipController, "Địa chỉ IP PC", Icons.wifi),
            _input(_userController, "User Windows", Icons.person),
            _input(_passController, "Pass Windows", Icons.lock, isPass: true),
            _input(_shareNameController, "Tên Folder đã Share", Icons.folder_shared),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 55)),
              onPressed: _connect,
              child: const Text("KẾT NỐI TRỰC TIẾP"),
            )
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String label, IconData icon, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        obscureText: isPass,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

class MangaListScreen extends StatefulWidget {
  final String ip, user, pass, share;
  const MangaListScreen({super.key, required this.ip, required this.user, required this.pass, required this.share});

  @override
  State<MangaListScreen> createState() => _MangaListScreenState();
}

class _MangaListScreenState extends State<MangaListScreen> {
  late SmbClient client;
  List<SmbFile> _folders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _setupSmb();
  }

  Future<void> _setupSmb() async {
    client = SmbClient(server: widget.ip, share: widget.share, username: widget.user, password: widget.pass);
    try {
      final files = await client.listFiles("");
      setState(() {
        _folders = files.where((f) => f.isDirectory).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi kết nối PC: $e")));
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
              leading: const Icon(Icons.folder, color: Colors.amber),
              title: Text(_folders[index].name),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => MangaReader(client: client, path: _folders[index].name),
              )),
            ),
          ),
    );
  }
}

class MangaReader extends StatelessWidget {
  final SmbClient client;
  final String path;
  const MangaReader({super.key, required this.client, required this.path});

  Future<List<Uint8List>> _loadImages() async {
    final files = await client.listFiles(path);
    List<Uint8List> images = [];
    final imageFiles = files.where((f) => f.name.toLowerCase().endsWith('.jpg') || f.name.toLowerCase().endsWith('.png')).toList();
    imageFiles.sort((a, b) => a.name.compareTo(b.name));

    for (var f in imageFiles) {
      final bytes = await client.readBinary("$path/${f.name}");
      images.add(bytes);
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Uint8List>>(
        future: _loadImages(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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