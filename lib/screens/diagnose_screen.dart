import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/design_system.dart';
import '../services/plant_disease_service.dart';
import '../services/database_service.dart';
import '../models/diagnosis_record.dart';
import 'diagnosis_detail_screen.dart';

class DiagnoseScreen extends StatefulWidget {
  final String selectedPlant;

  const DiagnoseScreen({super.key, required this.selectedPlant});

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();

      if (status.isGranted) {
        _cameras = await availableCameras();

        if (_cameras != null && _cameras!.isNotEmpty) {
          _controller = CameraController(
            _cameras![0],
            ResolutionPreset.high,
            enableAudio: false,
          );

          await _controller!.initialize();

          if (mounted) {
            setState(() => _isLoading = false);
          }
        } else {
          setState(() {
            _errorMessage = 'Không tìm thấy camera';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Cần quyền truy cập camera để chẩn đoán';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khởi tạo camera: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndDiagnose() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    try {
      final xFile = await _controller!.takePicture();
      await _processImageAndDiagnose(xFile.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chụp ảnh: $e'),
          backgroundColor: FarmColors.error,
        ),
      );
    }
  }

  Future<void> _pickImageAndDiagnose() async {
    if (_isProcessing) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        await _processImageAndDiagnose(pickedFile.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn ảnh: $e'),
          backgroundColor: FarmColors.error,
        ),
      );
    }
  }

  Future<void> _processImageAndDiagnose(String sourcePath) async {
    setState(() => _isProcessing = true);

    try {
      // Save to app directory for persistence
      final appDir = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${appDir.path}/diagnoses');
      if (!await savedDir.exists()) await savedDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = '${savedDir.path}/diagnosis_$timestamp.jpg';
      await File(sourcePath).copy(savedPath);

      // Run inference using selected plant
      final service = PlantDiseaseService();
      final result = await service.classify(savedPath, widget.selectedPlant);

      // Get disease info
      final info = PlantDiseaseService.getOverview(result.label);

      final now = DateTime.now();
      final dateStr =
          '${now.day}/${now.month}/${now.year} | ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final record = DiagnosisRecord(
        date: dateStr,
        plantName: result.plantName,
        diseaseName: result.isHealthy ? 'Khỏe mạnh' : result.diseaseName,
        confidence: result.confidence.round(),
        imagePath: savedPath,
        overview: info['overview'] ?? '',
        cause: info['cause'] ?? '',
        signs: info['signs'] ?? '',
        solutions: (info['solutions'] ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );

      // Save to database
      await DatabaseService().insertRecord(record);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Navigate to detail
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => DiagnosisDetailScreen(record: record)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chẩn đoán: $e'),
          backgroundColor: FarmColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: FarmColors.background,
        appBar: AppBar(title: const Text('Chẩn đoán')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: FarmColors.error),
                const SizedBox(height: 16),
                Text(_errorMessage,
                    textAlign: TextAlign.center,
                    style: FarmTextStyles.bodyLarge),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async => await openAppSettings(),
                  icon: const Icon(Icons.settings),
                  label: const Text('Mở Cài đặt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FarmColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: Text('Đang tải camera...',
                style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),

          CustomPaint(painter: _CameraOverlayPainter()),

          // Capture button & Gallery button
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gallery Button
                GestureDetector(
                  onTap: _isProcessing ? null : _pickImageAndDiagnose,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                // Capture Button
                GestureDetector(
                  onTap: _isProcessing ? null : _takePictureAndDiagnose,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Invisible placeholder to keep the capture button centered
                const SizedBox(width: 60),
              ],
            ),
          ),

          // Back button + instruction
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Đặt lá cây vào khung hình và chụp',
                      textAlign: TextAlign.center,
                      style: FarmTextStyles.bodyMedium
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Đang phân tích hình ảnh...',
                      style: FarmTextStyles.bodyLarge
                          .copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI đang chẩn đoán bệnh cây trồng',
                      style: FarmTextStyles.bodyMedium
                          .copyWith(color: Colors.white70),
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

class _CameraOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.height * 0.5,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      paint,
    );

    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = FarmColors.accent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top),
        Offset(rect.left + cornerLength, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.top),
        Offset(rect.left, rect.top + cornerLength), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(rect.right, rect.top),
        Offset(rect.right - cornerLength, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom),
        Offset(rect.left + cornerLength, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom),
        Offset(rect.left, rect.bottom - cornerLength), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(rect.right, rect.bottom),
        Offset(rect.right - cornerLength, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
