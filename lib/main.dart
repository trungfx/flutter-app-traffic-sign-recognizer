import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

import 'setting.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhận dạng biển báo giao thông',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class TrafficSign {
  final String id;
  final String name;
  final String accuracy;

  TrafficSign({
    required this.id,
    required this.name,
    required this.accuracy,
  });

  factory TrafficSign.fromJson(Map<String, dynamic> json) {
    return TrafficSign(
      id: json['id'],
      name: json['name'],
      accuracy: json['accuracy'],
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final Rect rect;

  BoundingBoxPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class HomePage extends StatefulWidget {
  // const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  int? _imageWidth = 0;
  int? _imageHeight = 0;
  List<TrafficSign>? _trafficSign;
  bool _isLoading = false;
  bool _imageSelected = false;
  // thêm biến này để kiểm tra ảnh đã được chọn hay chưa
  final GlobalKey imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  Future<void> getImageFromGallery() async {
    final imagePicker = ImagePicker();
    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) {
      return;
    }
    setState(() {
      _imageSelected = true;
      // cập nhật biến _imageSelected khi ảnh đã được chọn
      _image = File(pickedImage.path);
      _trafficSign = null;

      // Lấy kích thước ảnh
      img.Image? image = img.decodeImage(_image!.readAsBytesSync());
      _imageWidth = image?.width;
      _imageHeight = image?.height;
    });
  }

  Future<void> getImageFromCamera() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedImage == null) {
      return;
    }
    setState(() {
      _imageSelected = true;
      // cập nhật biến _imageSelected khi ảnh đã được chọn
      _image = File(pickedImage.path);
      _trafficSign = null;

      // Lấy kích thước ảnh
      img.Image? image = img.decodeImage(_image!.readAsBytesSync());
      _imageWidth = image?.width;
      _imageHeight = image?.height;
    });
  }

  Future updateUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String apiUrl =
        prefs.getString('currentUrl') ?? 'http://10.0.2.2:5000/image';
    return apiUrl;
  }

  Future identifyImage() async {
    setState(() {
      _isLoading = true;
    });
    String apiUrl = await updateUrl();
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    if (_image != null) {
      request.files
          .add(await http.MultipartFile.fromPath('file', _image!.path));
    }
    http.StreamedResponse response;
    try {
      response = await request.send();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Lỗi'),
            content: const Text('Đã có lỗi xảy ra khi gửi yêu cầu đến server'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }
    if (response.statusCode == 200) {
      var responseString = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseString);

      // ignore: avoid_print
      print(jsonResponse);
      List<dynamic> celebrityJson = jsonResponse;
      List<TrafficSign> celebrities =
          celebrityJson.map((json) => TrafficSign.fromJson(json)).toList();

      setState(() {
        _isLoading = false;
        _trafficSign = celebrities;
      });
    } else {
      setState(() {
        _isLoading = false;
        _trafficSign = null; // thêm dòng này để khắc phục lỗi
      });
      // ignore: avoid_print
      // print('Error: ${response.statusCode}');
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Lỗi'),
            content: const Text('Đã có lỗi xảy ra khi nhận diện ảnh'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_trafficSign != null || _isLoading || _imageSelected) {
      // Nếu có kết quả nhận dạng, yêu cầu xác nhận trước khi đóng trang
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bạn có chắc muốn hủy bỏ việc nhận dạng ảnh?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Có'),
            ),
          ],
        ),
      );
      if (confirm) {
        cancelIdentifyImage();
      }
      return Future.value(false);
    } else {
      // Nếu không có kết quả nhận dạng, cho phép đóng trang
      return Future.value(true);
    }
  }

  void cancelIdentifyImage() {
    // hàm để huỷ xử lý nhận diện
    setState(() {
      _isLoading = false;
      _imageSelected = false;
      _image = null;
      _trafficSign = null;
      _imageWidth = 0;
      _imageHeight = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nhận dạng biển báo giao thông'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingPage()),
                );
              },
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageSelected)
                Expanded(
                  child:
                      Image.file(_image!, key: imageKey, fit: BoxFit.fitWidth),
                ),
              if (_imageSelected) const SizedBox(height: 10.0),
              if (_imageSelected)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Text(
                    '$_imageWidth x $_imageHeight',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              const SizedBox(height: 16.0),
              if (!_imageSelected)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: getImageFromGallery,
                      highlightColor:
                          Colors.transparent, // tắt hiệu ứng khi nhấn
                      splashColor:
                          Colors.transparent, // tắt hiệu ứng khi splash
                      child: Column(
                        children: [
                          Container(
                            width: 100.0,
                            height: 100.0,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Icon(Icons.photo_library, size: 50.0),
                          ),
                          const SizedBox(height: 8.0),
                          const Text('Chọn từ thư viện',
                              style: TextStyle(fontSize: 16.0)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: getImageFromCamera,
                      highlightColor:
                          Colors.transparent, // tắt hiệu ứng khi nhấn
                      splashColor:
                          Colors.transparent, // tắt hiệu ứng khi splash
                      child: Column(
                        children: [
                          Container(
                            width: 100.0,
                            height: 100.0,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Icon(Icons.camera_alt, size: 50.0),
                          ),
                          const SizedBox(height: 8.0),
                          const Text('Chụp ảnh',
                              style: TextStyle(fontSize: 16.0)),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16.0),
              if (_imageSelected && !_isLoading && _trafficSign == null)
                // hiển thị ảnh đã chọn và nút nhận diện
                ElevatedButton(
                  onPressed: _image == null ? null : identifyImage,
                  child: const Text('Nhận diện ngay'),
                ),
              const SizedBox(height: 16.0),
              if (_isLoading) // hiển thị tiêu đề "Đang nhận diện" khi đang xử lý
                const SpinKitRing(
                  color: Colors.blue,
                  size: 50.0,
                )
              else if (_trafficSign != null && _trafficSign!.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _trafficSign!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(
                          _trafficSign![index].name,
                          style: index == 0
                              ? const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                )
                              : null,
                        ),
                        // subtitle: Text(_trafficSign![index].description),
                        subtitle: Text(
                            "Độ chính xác: ${_trafficSign![index].accuracy}"),
                      );
                    },
                  ),
                )
              else if (_trafficSign != null && _trafficSign!.isEmpty)
                const Expanded(
                  child: Center(
                      child: Text("Không có biển báo giao thông trong ảnh.")),
                ),
              const SizedBox(height: 48.0),
              if (_imageSelected || _isLoading && _trafficSign == null)
                // hiển thị nút huỷ khi không có kết quả nhận diện
                FloatingActionButton(
                  onPressed: _onWillPop,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.close, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
