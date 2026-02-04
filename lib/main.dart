import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReaderScreen(),
    ));

class ReaderScreen extends StatefulWidget {
  @override
  _ReaderScreenState createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  double _fontSize = 18.0;
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Thay đổi màu nền dựa trên chế độ sáng/tối
      backgroundColor: _isDarkMode ? Color(0xFF1A1A1A) : Color(0xFFF5F5DC),
      appBar: AppBar(
        title: Text("App Đọc Truyện Offline"),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(icon: Icon(Icons.remove), onPressed: () => setState(() => _fontSize -= 2)),
          IconButton(icon: Icon(Icons.add), onPressed: () => setState(() => _fontSize += 2)),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          "CHƯƠNG 1: KHỞI ĐẦU\n\nĐây là nội dung truyện của bạn. Khi bạn cài app này lên iPhone, bạn có thể vuốt để đọc rất mượt mà. Flutter giúp chúng ta tạo ra giao diện đẹp mắt chỉ với vài dòng code.\n\n" * 10,
          style: TextStyle(
            fontSize: _fontSize,
            color: _isDarkMode ? Colors.white70 : Colors.black87,
            height: 1.6, // Khoảng cách giữa các dòng
          ),
        ),
      ),
    );
  }
}