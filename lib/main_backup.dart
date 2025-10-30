import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '去他妈的校园公益',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 控制器
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  // 用户设置
  double _fontSize = 24.0;
  Color _fontColor = Colors.black;
  double _textPositionX = 100.0;
  double _textPositionY = 148.0;

  // 临时图片
  Uint8List? _tempImageBytes;

  // 图片尺寸
  static const double imageWidth = 1280;
  static const double imageHeight = 2772;

  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _numberController.addListener(_generateTempImage);
    _textController.addListener(_generateTempImage);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // 加载用户偏好设置
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? 24.0;
      _fontColor = Color(prefs.getInt('fontColor') ?? Colors.black.value);
      _textPositionX = prefs.getDouble('textPositionX') ?? 100.0;
      _textPositionY = prefs.getDouble('textPositionY') ?? 148.0;
    });
    // 加载后生成初始图片
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateTempImage();
    });
  }

  // 保存用户偏好设置
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setInt('fontColor', _fontColor.value);
    await prefs.setDouble('textPositionX', _textPositionX);
    await prefs.setDouble('textPositionY', _textPositionY);
  }

  // 格式化数字为保留两位小数的字符串
  String _formatNumber(String input) {
    if (input.isEmpty) return '0.00';
    
    try {
      final number = double.parse(input);
      return number.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  // 生成临时图片
  Future<void> _generateTempImage() async {
    // 延迟一小段时间以避免过于频繁的重绘
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 实际生成带水印的图片
    _generateWatermarkedImage();
  }

  // 实际生成带水印的图片
  Future<void> _generateWatermarkedImage() async {
    try {
      // 创建一个PictureRecorder来记录绘制操作
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // 加载原始图片
      final ByteData? imageData = await rootBundle.load('assets/1.png');
      final ui.Codec codec = await ui.instantiateImageCodec(imageData!.buffer.asUint8List());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      
      // 绘制原始图片
      canvas.drawImage(originalImage, const Offset(0, 0), Paint());
      

      final formattedNumber = _formatNumber(_numberController.text);
      if (formattedNumber.isNotEmpty) {

        final numberFontSize = 55.0; // <<<--- 修改数字字体大小在此处
        
        final numberParagraph = _buildParagraph(formattedNumber, numberFontSize, Colors.black, true);
        
        // 计算文本宽度以实现右对齐
        final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          fontSize: numberFontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Microsoft YaHei',
        ))
          ..pushStyle(ui.TextStyle(color: Colors.black))
          ..addText(formattedNumber);
        
        final paragraph = paragraphBuilder.build()
          ..layout(const ui.ParagraphConstraints(width: double.infinity));
        
        final textWidth = paragraph.minIntrinsicWidth;
        
        
        final numberPosition = Offset(512 - textWidth, 464);
        canvas.drawParagraph(numberParagraph, numberPosition);
      }
      
      // 绘制个人信息
      if (_textController.text.isNotEmpty) {
        final textParagraph = _buildParagraph(_textController.text, _fontSize, _fontColor, false);
        canvas.drawParagraph(textParagraph, Offset(_textPositionX, _textPositionY));
      }
      
      // 完成绘制并生成图片
      final picture = recorder.endRecording();
      final img = await picture.toImage(imageWidth.toInt(), imageHeight.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        setState(() {
          _tempImageBytes = byteData.buffer.asUint8List();
        });
      }
    } catch (e) {
      // 出错时显示错误信息
      print('生成图片时出错: $e');
    }
  }
  
  // 构建文本段落
  ui.Paragraph _buildParagraph(String text, double fontSize, Color color, bool isBold) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontFamily: 'Microsoft YaHei',
    ))
      ..pushStyle(ui.TextStyle(
        color: color,
      ))
      ..addText(text);
    
    return builder.build()
      ..layout(const ui.ParagraphConstraints(width: 1280));
  }

  // 显示全屏预览
  void _showFullScreenPreview() {
    if (_tempImageBytes != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenPage(imageBytes: _tempImageBytes!),
        ),
      );
    } else {
      // 如果没有临时图片，则提示用户
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入数字并生成图片')),
      );
    }
  }

  // 导出图片提示
  void _exportImage() {
    // 先生成带水印的图片
    _generateWatermarkedImage();
    
    // 延迟一小段时间确保图片生成完成
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_tempImageBytes != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('导出图片'),
              content: const Text('请稍后自行截图'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showFullScreenPreview();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片生成中，请稍后再试')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedNumber = _formatNumber(_numberController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('去他妈的校园公益'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 数字输入区域
            const Text('输入数字:'),
            TextField(
              controller: _numberController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '输入一个数字',
              ),
            ),
            const SizedBox(height: 16),
            
            // 个人信息设置区域
            const Text('个人信息设置:'),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: '输入个人信息',
              ),
            ),
            const SizedBox(height: 8),
            
            // 字体大小设置
            Row(
              children: [
                const Text('字体大小:'),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 10,
                    max: 72,
                    divisions: 62,
                    onChanged: (value) {
                      setState(() {
                        _fontSize = value;
                      });
                      _savePreferences();
                    },
                    onChangeEnd: (value) {
                      _generateTempImage();
                    },
                  ),
                ),
                Text('${_fontSize.toStringAsFixed(0)}'),
              ],
            ),
            
            // 字体颜色选择
            Row(
              children: [
                const Text('字体颜色:'),
                IconButton(
                  onPressed: () async {
                    final color = await _pickColor();
                    if (color != null) {
                      setState(() {
                        _fontColor = color;
                      });
                      _savePreferences();
                      _generateTempImage();
                    }
                  },
                  icon: Icon(
                    Icons.color_lens,
                    color: _fontColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 文字位置设置（简化版）
            const Text('文字位置: 可通过拖拽调整(简化版)'),
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: _textPositionX * 0.2, // 简化比例
                    top: _textPositionY * 0.05, // 简化比例
                    child: GestureDetector(
                      onTap: () {
                        // 这里应该实现拖拽功能
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('实际应用中可以拖拽调整位置')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.blue.withOpacity(0.3),
                        child: const Text('拖拽我'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 预览区域
            const Text('图片预览:'),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  color: Colors.grey[200],
                ),
                child: _tempImageBytes != null 
                  ? Image.memory(_tempImageBytes!)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image, size: 50, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text('顶部数字: $formattedNumber\n个人信息: ${_textController.text}',
                               textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          const Text('正在生成预览...',
                               style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 导出按钮
            Center(
              child: ElevatedButton(
                onPressed: _exportImage,
                child: const Text('导出图片'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 颜色选择器（简化版）
  Future<Color?> _pickColor() async {
    return showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              onColorChanged: (Color color) {},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(Colors.black),
              child: const Text('黑色'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(Colors.red),
              child: const Text('红色'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(Colors.blue),
              child: const Text('蓝色'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(Colors.green),
              child: const Text('绿色'),
            ),
          ],
        );
      },
    );
  }
}

// 颜色选择器组件
class ColorPicker extends StatefulWidget {
  final Function(Color) onColorChanged;

  const ColorPicker({super.key, required this.onColorChanged});

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  Color _selectedColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 100,
          color: _selectedColor,
        ),
        const SizedBox(height: 10),
        const Text('选择一个颜色'),
      ],
    );
  }
}

// 全屏预览页面
class FullScreenPage extends StatefulWidget {
  final Uint8List imageBytes;

  const FullScreenPage({super.key, required this.imageBytes});

  @override
  State<FullScreenPage> createState() => _FullScreenPageState();
}

class _FullScreenPageState extends State<FullScreenPage> {
  @override
  void initState() {
    super.initState();
    // 直接显示系统UI而不是隐藏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.black,
          child: Center(
            child: InteractiveViewer(
              child: Image.memory(
                widget.imageBytes,
                fit: BoxFit.cover, // 使用BoxFit.cover填充整个屏幕空间，消除黑边
                filterQuality: FilterQuality.high,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
