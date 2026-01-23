import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';

class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({super.key});

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _loadModel();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Initialize the first camera (rear usually)
        _cameraController = CameraController(
          _cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _loadModel() async {
    try {
      // Placeholder for model loading
      // _interpreter = await Interpreter.fromAsset('assets/models/plant_disease_model.tflite');
      // setState(() => _isModelLoaded = true);
      debugPrint("Model loading placeholder: Model not yet in assets");
    } catch (e) {
      debugPrint("Model Error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  // Manage lifecycle to pause camera when app is in background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return;
    }

    try {
      final XFile file = await _cameraController!.takePicture();
      setState(() {
        _imagePath = file.path;
      });
      // Here usually we would crop and pass _imagePath to the TFLite interpreter
      _analyzeImage(file.path);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _analyzeImage(String path) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Image captured! Analysis pending model integration."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_imagePath != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Result'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _imagePath = null),
          ),
        ),
        body: Column(
          children: [
            Expanded(child: Image.file(File(_imagePath!))),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Diagnosis: Healthy (Mock)",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Full Screen Camera Preview
          SizedBox.expand(child: CameraPreview(_cameraController!)),

          // Overlay UI
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.large(
                onPressed: _takePicture,
                child: const Icon(Icons.camera),
              ),
            ),
          ),

          // Top Back Button
          Positioned(
            top: 40,
            left: 10,
            child: IconButton.filledTonal(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Determine if we need pop or switching tab.
                // Since this is a Tab, "Back" implies going to Home Tab?
                // Or maybe just do nothing if it's the main Diagnose tab.
                // For now, let's just show a snackbar or allow standard Nav bar switching.
              },
            ),
          ),
        ],
      ),
    );
  }
}
