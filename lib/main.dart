import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

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
      _fontSize = prefs.getDouble('fontSize') ?? 70.0;
      _fontColor = Color(prefs.getInt('fontColor') ?? Colors.black.value);
      _textPositionX = prefs.getDouble('textPositionX') ?? 100.0;
      _textPositionY = prefs.getDouble('textPositionY') ?? 148.0;
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
      ByteData? imageData;
      try {
        imageData = await rootBundle.load('assets/1.png');
      } catch (e) {
        print('加载图片资源失败: $e');
        // 如果加载失败，创建一个纯色背景作为替代
        final paint = Paint()..color = Colors.grey;
        canvas.drawRect(Rect.fromLTWH(0, 0, imageWidth, imageHeight), paint);
      }
      
      if (imageData != null) {
        try {
          final ui.Codec codec = await ui.instantiateImageCodec(imageData.buffer.asUint8List());
          final ui.FrameInfo frameInfo = await codec.getNextFrame();
          final ui.Image originalImage = frameInfo.image;
          
          // 绘制原始图片
          canvas.drawImage(originalImage, const Offset(0, 0), Paint());
        } catch (e) {
          print('解码图片失败: $e');
          // 如果解码失败，创建一个纯色背景作为替代
          final paint = Paint()..color = Colors.grey;
          canvas.drawRect(Rect.fromLTWH(0, 0, imageWidth, imageHeight), paint);
        }
      }

      final formattedNumber = _formatNumber(_numberController.text);
      if (formattedNumber.isNotEmpty) {
        final numberFontSize = 55.0; // <<<--- 修改数字字体大小在此处
        
        final numberParagraph = _buildParagraph(formattedNumber, numberFontSize, Colors.black, true); // 修复参数
        
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
      
      // 完成绘制并生成图片
      final picture = recorder.endRecording();
      final img = await picture.toImage(imageWidth.toInt(), imageHeight.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        setState(() {
          _tempImageBytes = byteData.buffer.asUint8List();
        });
      }
    } catch (e, stack) {
      // 出错时显示错误信息
      print('生成图片时出错: $e');
      print('错误堆栈: $stack');
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenPage(imageBytes: _tempImageBytes!),
      ),
    );
  }

  // 导出图片
  Future<void> _exportImage() async {
    // 改为显示全屏预览而不是保存图片
    if (_tempImageBytes != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenPage(
            imageBytes: _tempImageBytes!,
            personalInfo: _textController.text.isEmpty ? '个人信息' : _textController.text, // 传递用户输入的个人信息
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('图片生成中，请稍后再试')),
      );
    }
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
              maxLines: 3, // 支持多行输入
              textAlign: TextAlign.center, // 文本居中对齐
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
                  ? Center(
                      child: Image.memory(_tempImageBytes!),
                    )
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
}

// 全屏预览页面
class FullScreenPage extends StatefulWidget {
  final Uint8List imageBytes;
  final String personalInfo; // 添加个人信息参数

  const FullScreenPage({super.key, required this.imageBytes, this.personalInfo = '个人信息'});

  @override
  State<FullScreenPage> createState() => _FullScreenPageState();
}

class _FullScreenPageState extends State<FullScreenPage> {
  late double _textPositionX;
  late double _textPositionY;
  late double _fontSize;
  late Color _fontColor;
  late String _personalInfo; // 添加个人信息变量

  @override
  void initState() {
    super.initState();
    // 直接显示系统UI而不是隐藏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // 初始化个人信息位置和样式
    _textPositionX = 100.0;
    _textPositionY = 148.0;
    _fontSize = 30.0; // 修改默认字体大小为30
    _fontColor = Colors.black;
    _personalInfo = widget.personalInfo; // 使用传入的个人信息
    
    // 加载保存的设置
    _loadPreferences();
  }

  // 加载用户偏好设置
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? 30.0; // 修改默认字体大小为30
      _fontColor = Color(prefs.getInt('fontColor') ?? Colors.black.value);
      _textPositionX = prefs.getDouble('textPositionX') ?? 100.0;
      _textPositionY = prefs.getDouble('textPositionY') ?? 148.0;
      // 如果widget传递了有效的个人信息，则使用它；否则从SharedPreferences加载
      if (widget.personalInfo != '个人信息' && widget.personalInfo.isNotEmpty) {
        _personalInfo = widget.personalInfo;
      } else {
        _personalInfo = prefs.getString('personalInfo') ?? '个人信息';
      }
    });
  }

  // 保存用户偏好设置
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setInt('fontColor', _fontColor.value);
    await prefs.setDouble('textPositionX', _textPositionX);
    await prefs.setDouble('textPositionY', _textPositionY);
    await prefs.setString('personalInfo', _personalInfo); // 保存个人信息
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 显示个人信息设置对话框
  Future<void> _showTextSettings() async {
    // 保存当前设置的副本
    double tempFontSize = _fontSize;
    Color tempFontColor = _fontColor;
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('个人信息设置'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 字体大小设置
                  Row(
                    children: [
                      const Text('字体大小:'),
                      Expanded(
                        child: Slider(
                          value: tempFontSize,
                          min: 20, // 修改最小值为20
                          max: 50, // 修改最大值为50
                          divisions: 30, // 修改分割数为30 (50-20=30)
                          label: tempFontSize.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              tempFontSize = value;
                            });
                          },
                        ),
                      ),
                      Text('${tempFontSize.round()}'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 字体颜色选择
                  Row(
                    children: [
                      const Text('字体颜色:'),
                      TextButton(
                        onPressed: () async {
                          final color = await _pickColor(context);
                          if (color != null) {
                            setState(() {
                              tempFontColor = color;
                            });
                          }
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: tempFontColor,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    // 只有在点击确定时才更新状态
                    setState(() {
                      _fontSize = tempFontSize;
                      _fontColor = tempFontColor;
                    });
                    Navigator.of(context).pop();
                    _savePreferences();
                  },
                  child: const Text('确定'),
                ),

              ],
            );
          },
        );
      },
    );
  }

  // 颜色选择器
  Future<Color?> _pickColor(BuildContext context) async {
    return showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(onColorChanged: (Color color) {}),
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
          color: Colors.transparent, // 移除白底，使用透明背景
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
              ),
              // 可拖动的个人信息
              Positioned(
                left: _textPositionX,
                top: _textPositionY,
                child: GestureDetector(
                  onTap: _showTextSettings,
                  onPanUpdate: (details) {
                    setState(() {
                      _textPositionX += details.delta.dx;
                      _textPositionY += details.delta.dy;
                    });
                    _savePreferences();
                  },
                  child: Text(
                    _personalInfo, // 显示用户输入的个人信息
                    style: TextStyle(
                      fontSize: _fontSize,
                      color: _fontColor,
                      // 移除背景色
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
