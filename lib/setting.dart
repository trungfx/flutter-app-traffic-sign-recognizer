import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  // khai báo biến để lưu URL
  final TextEditingController _urlController = TextEditingController();

  // khai báo biến để lưu trạng thái của nút Chỉnh sửa/Lưu/Xóa
  bool _isEditing = false;

  // khai báo biến để lưu URL hiện tại
  late String _currentUrl;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  // hàm để khởi tạo giá trị ban đầu cho biến _urlController và _currentUrl từ Shared Preferences
  void _initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUrl =
          prefs.getString('currentUrl') ?? 'http://10.0.2.2:5000/image';
      _urlController.text = _currentUrl;
      _urlController.selection = TextSelection.fromPosition(
          TextPosition(offset: _urlController.text.length));
    });
  }

// hàm để xử lý sự kiện khi nhấn vào nút Chỉnh sửa/Lưu/Xóa
  void _onEditButtonPressed() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_isEditing) {
        // nếu đang ở trạng thái Chỉnh sửa, thì lưu URL mới vào Shared Preferences và chuyển về trạng thái Xem
        _currentUrl = _urlController.text;
        prefs.setString('currentUrl', _currentUrl);
        _isEditing = false;
      } else {
        // nếu đang ở trạng thái Xem, thì lấy URL hiện tại từ Shared Preferences và hiển thị lên TextField
        _currentUrl =
            prefs.getString('currentUrl') ?? 'http://10.0.2.2:5000/image';
        _urlController.text = _currentUrl;
        _urlController.selection = TextSelection.fromPosition(
            TextPosition(offset: _urlController.text.length));
        _isEditing = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _onEditButtonPressed,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API URL:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            // ElevatedButton(
            //   onPressed: _onEditButtonPressed,
            //   child: Text(_isEditing ? 'Lưu' : 'Chỉnh sửa'),
            // ),
          ],
        ),
      ),
    );
  }
}
