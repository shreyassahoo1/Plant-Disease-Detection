import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import '../../../providers/ai_analysis_provider.dart';
import '../../../core/localization/translations.dart';
import '../../../data/models/disease_result.dart';
import '../../widgets/esp32_cam_viewer.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _useRoverCam = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(cameras[0], ResolutionPreset.max);
        await _controller!.initialize();
        if (mounted) setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    if (_useRoverCam) {
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.greenAccent),
          ),
        );

        final captureUrl = dotenv.env['ROVER_ESP32_CAM_CAPTURE_URL'] ?? 'http://172.20.10.7:81/capture
';
        
        final dio = Dio();
        final response = await dio.get<List<int>>(
          captureUrl,
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
          ),
        );

        if (navigator.canPop()) {
          navigator.pop();
        }

        if (response.data == null || response.data!.isEmpty) {
          throw Exception('Received empty image data from ESP32 Cam');
        }

        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/rover_capture_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(response.data!);

        // Crop Image Flow
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: file.path,
          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: 'Crop Plant Image',
                toolbarColor: primaryColor,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: false),
            IOSUiSettings(
              title: 'Crop Plant Image',
            ),
          ],
        );

        if (!mounted) return;

        if (croppedFile != null) {
          setState(() => _capturedImagePath = croppedFile.path);
        } else {
          setState(() => _capturedImagePath = file.path);
        }
      } catch (e) {
        if (navigator.canPop()) {
          navigator.pop();
        }
        debugPrint('Capture from ESP32 error: $e');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (!_isCameraInitialized || _controller == null) {
      // Fallback if no real camera
      setState(() => _capturedImagePath = 'mobile_simulated_image');
      return;
    }

    try {
      final image = await _controller!.takePicture();
      
      // Crop Image Flow
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop Plant Image',
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Crop Plant Image',
          ),
        ],
      );

      if (!mounted) return;

      if (croppedFile != null) {
        setState(() => _capturedImagePath = croppedFile.path);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      setState(() => _capturedImagePath = 'mobile_simulated_error_image');
    }
  }

  void _analyzeImage() {
    if (_capturedImagePath == null) return;
    ref.read(aiAnalysisProvider.notifier).analyzeImage(_capturedImagePath!);
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiAnalysisProvider);
    final theme = Theme.of(context);

    // Determine background color based on state
    Color screenBgColor = Colors.black;
    if (aiState is AsyncData && aiState.value != null) {
      final result = aiState.value!;
      final isHealthy = result.diseaseName.toLowerCase().contains('healthy');
      screenBgColor = isHealthy ? Colors.teal.shade900 : Colors.red.shade900;
    }

    return Scaffold(
      backgroundColor: screenBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Smart Scan'.tr(ref)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          Row(
            children: [
              Text('Rover Cam'.tr(ref), style: const TextStyle(color: Colors.white)),
              Switch(
                value: _useRoverCam,
                activeColor: theme.colorScheme.primary,
                onChanged: (val) {
                  setState(() {
                    _useRoverCam = val;
                    _capturedImagePath = null;
                    ref.read(aiAnalysisProvider.notifier).reset();
                  });
                },
              ),
            ],
          )
        ],
      ),
      body: aiState.when(
        data: (result) {
          if (result != null) return _buildResultView(result);
          if (_capturedImagePath != null) return _buildPreviewView();
          return _buildCameraView();
        },
        loading: () => _buildLoadingView(),
        error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        if (_useRoverCam)
          Positioned.fill(
            child: ESP32CamViewer(
              streamUrl: dotenv.env['ROVER_ESP32_CAM_STREAM_URL'] ?? 'http://172.20.10.7:81/stream
',
            ),
          )
        else if (_isCameraInitialized && _controller != null)
          Positioned.fill(child: CameraPreview(_controller!))
        else
          const Center(child: Icon(LucideIcons.camera, size: 64, color: Colors.white54)),
        
        // Custom Viewfinder Overlay - Gridlines
        if (!_useRoverCam && _isCameraInitialized)
          Positioned.fill(
            child: CustomPaint(
              painter: GridOverlayPainter(),
            ),
          ),

        // Capture Button
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: GestureDetector(
              onTap: _takePicture,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewView() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: _capturedImagePath!.contains('simulated')
                ? const Icon(LucideIcons.image, size: 100, color: Colors.white)
                : Image.file(File(_capturedImagePath!)),
          ),
        ),
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _capturedImagePath = null),
                icon: const Icon(LucideIcons.x, color: Colors.white),
                label: Text('Retake'.tr(ref), style: const TextStyle(color: Colors.white)),
              ),
              ElevatedButton.icon(
                onPressed: _analyzeImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(LucideIcons.sparkles),
                label: Text('Analyze Image'.tr(ref)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.greenAccent),
          const SizedBox(height: 24),
          Text('AI is analyzing the scan...'.tr(ref), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.greenAccent)),
          const SizedBox(height: 8),
          Text('Identifying diseases and formulating remedies.'.tr(ref), style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildResultView(DiseaseResult result) {
    final isHealthy = result.diseaseName.toLowerCase().contains('healthy');
    final resultColor = isHealthy ? Colors.greenAccent : Colors.redAccent;
    final emoji = isHealthy ? '🌿 😊' : '🥀 ⚠️';
    final screenBgColor = isHealthy ? Colors.teal.shade900 : Colors.red.shade900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: resultColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: resultColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(result.diseaseName, 
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('${'Confidence'.tr(ref)}: ${result.confidence}%', 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Precautions
          if (result.precautions.isNotEmpty) ...[
            Text('Precautions & Care'.tr(ref), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            ...result.precautions.map<Widget>((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(isHealthy ? LucideIcons.checkCircle : LucideIcons.shieldAlert, color: resultColor),
                title: Text(p, style: const TextStyle(color: Colors.white)),
              ),
            )),
          ],
          
          const SizedBox(height: 24),
          
          // Fertilizers
          if (result.indianFertilizers.isNotEmpty) ...[
            Text('Recommended Indian Fertilizers'.tr(ref), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            ...result.indianFertilizers.map<Widget>((f) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: const Icon(LucideIcons.leaf, color: Colors.green),
                title: Text(f, style: const TextStyle(color: Colors.white)),
              ),
            )),
          ],

          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _capturedImagePath = null;
                ref.read(aiAnalysisProvider.notifier).reset();
              });
            },
            icon: const Icon(LucideIcons.scanLine),
            label: Text('Scan Another Crop'.tr(ref)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: screenBgColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Custom Painter for 3x3 Gridlines
class GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0;

    // Draw vertical lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);

    // Draw horizontal lines
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
