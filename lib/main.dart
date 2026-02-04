import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Để encode/decode JSON
import 'dart:io'; // Để tạo thư mục giả lập (chỉ trên Android/desktop, không trên iOS)

// --- Màn hình đọc truyện (Giữ nguyên từ phiên bản trước, nhưng sẽ được gọi từ MangaStudioScreen) ---
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

// --- Mẫu dữ liệu cho một bộ truyện ---
class Manga {
  String id;
  String title;
  String coverImagePath; // Đường dẫn ảnh bìa
  List<Chapter> chapters; // Danh sách các chương
  String description;

  Manga({
    required this.id,
    required this.title,
    required this.coverImagePath,
    this.chapters = const [],
    this.description = "",
  });

  // Chuyển đối tượng Manga sang JSON để lưu vào SharedPreferences
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'coverImagePath': coverImagePath,
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'description': description,
      };

  // Tạo đối tượng Manga từ JSON
  factory Manga.fromJson(Map<String, dynamic> json) => Manga(
        id: json['id'],
        title: json['title'],
        coverImagePath: json['coverImagePath'],
        chapters: (json['chapters'] as List)
            .map((c) => Chapter.fromJson(c))
            .toList(),
        description: json['description'],
      );
}

// --- Mẫu dữ liệu cho một chương truyện ---
class Chapter {
  String id;
  String title;
  List<String> pageImagePaths; // Danh sách đường dẫn ảnh các trang

  Chapter({
    required this.id,
    required this.title,
    required this.pageImagePaths,
  });

  // Chuyển đối tượng Chapter sang JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'pageImagePaths': pageImagePaths,
      };

  // Tạo đối tượng Chapter từ JSON
  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'],
        title: json['title'],
        pageImagePaths: (json['pageImagePaths'] as List<dynamic>)
            .map((e) => e.toString())
            .toList(),
      );
}

// --- Màn hình chính Manga App ---
void main() => runApp(const MangaApp());

class MangaApp extends StatelessWidget {
  const MangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Nền tối chuyên nghiệp
        primaryColor: Colors.deepOrangeAccent,
        textTheme: GoogleFonts.lexendTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E1E1E), // Appbar màu xám đậm
          elevation: 1,
          titleTextStyle: GoogleFonts.russoOne(
            color: Colors.white,
            fontSize: 22,
            letterSpacing: 1,
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1A1A),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      home: const MangaStudioScreen(),
    );
  }
}

// --- Màn hình Manga Studio (Quản lý truyện) ---
class MangaStudioScreen extends StatefulWidget {
  const MangaStudioScreen({super.key});

  @override
  State<MangaStudioScreen> createState() => _MangaStudioScreenState();
}

class _MangaStudioScreenState extends State<MangaStudioScreen> {
  List<Manga> _mangaList = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadMangaList();
  }

  // Tải danh sách manga đã lưu từ SharedPreferences
  Future<void> _loadMangaList() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mangaJson = prefs.getString('manga_list');
    if (mangaJson != null) {
      final List<dynamic> decodedList = json.decode(mangaJson);
      setState(() {
        _mangaList = decodedList.map((item) => Manga.fromJson(item)).toList();
      });
    }
  }

  // Lưu danh sách manga vào SharedPreferences
  Future<void> _saveMangaList() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(_mangaList.map((m) => m.toJson()).toList());
    await prefs.setString('manga_list', encodedList);
  }

  // Hàm tạo manga mới (mô phỏng)
  void _createNewManga() async {
    // Tạo ID ngẫu nhiên cho manga mới
    String newMangaId = DateTime.now().millisecondsSinceEpoch.toString();
    String newMangaTitle = "Manga mới ${newMangaId.substring(newMangaId.length - 4)}";
    String coverPath = 'assets/chapters/chap1/1.jpg'; // Ảnh bìa mặc định

    // Giả lập việc tạo một chương đầu tiên với ảnh mẫu
    Chapter defaultChapter = Chapter(
      id: "chap_${DateTime.now().microsecondsSinceEpoch}",
      title: "Chương 1: Khởi đầu",
      pageImagePaths: List.generate(
        10, // Số trang mặc định
        (index) => 'assets/chapters/chap1/${index + 1}.jpg',
      ),
    );

    Manga newManga = Manga(
      id: newMangaId,
      title: newMangaTitle,
      coverImagePath: coverPath,
      chapters: [defaultChapter],
      description: "Một bộ truyện mới được tạo.",
    );

    setState(() {
      _mangaList.add(newManga);
    });
    await _saveMangaList(); // Lưu ngay sau khi tạo
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(content: Text('Đã tạo truyện "${newManga.title}"!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('MANGA STUDIO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Quay lại màn hình trước đó nếu có
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewManga, // Nút tạo manga mới
            tooltip: 'Tạo Manga mới',
          ),
        ],
      ),
      drawer: _buildDrawer(context), // Menu bên trái
      body: _mangaList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.book_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  Text("Chưa có truyện nào được tạo.",
                      style: GoogleFonts.lexend(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _createNewManga,
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text("Tạo truyện đầu tiên"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Hiển thị 2 cột
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7, // Tỷ lệ chiều rộng/chiều cao của mỗi thẻ truyện
              ),
              itemCount: _mangaList.length,
              itemBuilder: (context, index) {
                final manga = _mangaList[index];
                return GestureDetector(
                  onTap: () {
                    // Chuyển đến màn hình đọc chương đầu tiên của manga này
                    if (manga.chapters.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MangaReaderScreen(
                            manga: manga,
                            chapter: manga.chapters.first,
                          ),
                        ),
                      );
                    } else {
                      _scaffoldKey.currentState?.showSnackBar(
                        const SnackBar(content: Text('Truyện này chưa có chương nào!')),
                      );
                    }
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias, // Cắt ảnh theo bo góc của Card
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.asset(
                            manga.coverImagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            manga.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, bottom: 8.0),
                          child: Text(
                            manga.description,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Widget cho menu bên trái
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              'Tùy chọn Studio',
              style: GoogleFonts.russoOne(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_box_outlined, color: Colors.white70),
            title: const Text('Tạo Manga mới', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context); // Đóng Drawer
              _createNewManga();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white70),
            title: const Text('Cài đặt', style: TextStyle(color: Colors.white)),
            onTap: () {
              // TODO: Điều hướng đến màn hình cài đặt
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white70),
            title: const Text('Giới thiệu', style: TextStyle(color: Colors.white)),
            onTap: () {
              // TODO: Điều hướng đến màn hình giới thiệu
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined, color: Colors.white70),
            title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
            trailing: Switch(
              value: true, // Mặc định Dark Mode
              onChanged: (bool value) {
                // TODO: Triển khai chuyển đổi Dark/Light Mode
              },
              activeColor: Colors.deepOrangeAccent,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Màn hình đọc truyện (đã được cập nhật để nhận Manga và Chapter) ---
class MangaReaderScreen extends StatefulWidget {
  final Manga manga;
  final Chapter chapter;

  const MangaReaderScreen({
    super.key,
    required this.manga,
    required this.chapter,
  });

  @override
  State<MangaReaderScreen> createState() => _MangaReaderScreenState();
}

class _MangaReaderScreenState extends State<MangaReaderScreen> {
  late PageController _pageController;
  int _currentPage = 0; // Bắt đầu từ trang 0 (index của list)

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _loadReadingProgress();
  }

  @override
  void dispose() {
    _saveReadingProgress();
    _pageController.dispose();
    super.dispose();
  }

  // Tải trang đọc gần nhất
  Future<void> _loadReadingProgress() async {
    final prefs = await SharedPreferences.getInstance();
    // Key để lưu tiến độ đọc của một chapter cụ thể
    final String key = 'reading_progress_${widget.chapter.id}';
    final int? lastPage = prefs.getInt(key);
    if (lastPage != null && lastPage < widget.chapter.pageImagePaths.length) {
      setState(() {
        _currentPage = lastPage;
        _pageController = PageController(initialPage: _currentPage);
      });
    }
  }

  // Lưu trang đang đọc dở
  Future<void> _saveReadingProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'reading_progress_${widget.chapter.id}';
    await prefs.setInt(key, _currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6), // Appbar trong suốt một phần
        title: Text(widget.manga.title,
            style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {
              // TODO: Thêm tính năng đánh dấu bookmark
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đánh dấu trang này!')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.chapter.pageImagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              _saveReadingProgress(); // Lưu tiến độ ngay khi chuyển trang
            },
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: AssetImage(widget.chapter.pageImagePaths[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3.0,
                heroAttributes: PhotoViewHeroAttributes(tag: widget.chapter.id + index.toString()),
              );
            },
            scrollDirection: Axis.vertical,
            loadingBuilder: (context, event) => Center(
              child: SizedBox(
                width: 30.0,
                height: 30.0,
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                  value: event == null
                      ? null
                      : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                ),
              ),
            ),
          ),
          // Hiển thị thanh tiến trình ở cuối màn hình
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.black.withOpacity(0.6),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: widget.chapter.pageImagePaths.isEmpty
                          ? 0
                          : (_currentPage + 1) / widget.chapter.pageImagePaths.length,
                      backgroundColor: Colors.white10,
                      color: Theme.of(context).primaryColor,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    "${_currentPage + 1}/${widget.chapter.pageImagePaths.length}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}