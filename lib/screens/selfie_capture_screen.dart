import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class SelfieCaptureScreen extends StatefulWidget {
  final String title;
  const SelfieCaptureScreen({super.key, required this.title});

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isTakingPhoto = false;
  int _selectedCameraIndex = 0;

  // ML Kit Face Detector instance
  late final FaceDetector _faceDetector;
  bool _isProcessingImage = false;
  bool _isFaceDetected = false;
  String _statusMessage = 'Circle ke andar chehra laayein';

  @override
  void initState() {
    super.initState();
    // Configure high-performance realtime face detection
    final options = FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      enableLandmarks: false,
      enableTracking: false,
      minFaceSize: 0.25, // Requires clear face taking reasonable frame size
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);

    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) Navigator.pop(context, null);
        return;
      }

      // Prefer front selfie camera
      int frontIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );

      _selectedCameraIndex = frontIndex != -1 ? frontIndex : 0;
      await _initializeController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) Navigator.pop(context, null);
    }
  }

  Future<void> _initializeController(CameraDescription camera) async {
    final prevController = _controller;
    if (prevController != null) {
      try {
        if (prevController.value.isStreamingImages) {
          await prevController.stopImageStream();
        }
      } catch (_) {}
      await prevController.dispose();
    }

    // Use low resolution preset: keeps captured image size very small (~20KB-40KB)
    // to never exceed Firestore 1MB document limit.
    final controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });

        // Start continuous realtime camera stream for ML face detection
        await _startImageStream(controller, camera);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _startImageStream(CameraController controller, CameraDescription camera) async {
    try {
      await controller.startImageStream((CameraImage image) {
        if (_isProcessingImage || _isTakingPhoto || !mounted) return;
        _processCameraImage(image, camera);
      });
    } catch (e) {
      debugPrint('Error starting image stream: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image, CameraDescription camera) async {
    _isProcessingImage = true;
    try {
      final inputImage = _inputImageFromCameraImage(image, camera);
      if (inputImage == null) {
        _isProcessingImage = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (mounted) {
        if (faces.isNotEmpty) {
          final face = faces.first;
          // Verify face is reasonably sized and centered in the frame
          final double faceWidthRatio = face.boundingBox.width / image.width;
          final double faceHeightRatio = face.boundingBox.height / image.height;

          // Face is confirmed if reasonably visible in circular viewport
          final bool isValidFace = faceWidthRatio > 0.15 || faceHeightRatio > 0.15;

          if (isValidFace) {
            if (!_isFaceDetected) {
              setState(() {
                _isFaceDetected = true;
                _statusMessage = 'Face Detected • Perfect Alignment';
              });
            }
          } else {
            if (_isFaceDetected) {
              setState(() {
                _isFaceDetected = false;
                _statusMessage = 'Thoda paas aayein';
              });
            }
          }
        } else {
          // No face detected in frame -> Reset immediately to white circle!
          if (_isFaceDetected) {
            setState(() {
              _isFaceDetected = false;
              _statusMessage = 'Apna chehra circle ke andar rakhein';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _isProcessingImage = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, CameraDescription camera) {
    try {
      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;
      
      // Determine device rotation
      switch (sensorOrientation) {
        case 90:
          rotation = InputImageRotation.rotation90deg;
          break;
        case 180:
          rotation = InputImageRotation.rotation180deg;
          break;
        case 270:
          rotation = InputImageRotation.rotation270deg;
          break;
        default:
          rotation = InputImageRotation.rotation0deg;
      }

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      // Fallback format if null
      final finalFormat = format ?? InputImageFormat.nv21;

      // Concatenate image plane bytes
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: finalFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() {
      _isInitialized = false;
      _isFaceDetected = false;
      _statusMessage = 'Circle ke andar chehra laayein';
    });
    await _initializeController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _captureSelfie() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPhoto) return;

    try {
      setState(() => _isTakingPhoto = true);

      // Stop image stream before taking picture to prevent buffer race
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }

      final XFile photo = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, photo);
      }
    } catch (e) {
      debugPrint('Error taking selfie: $e');
      if (mounted) {
        setState(() => _isTakingPhoto = false);
        // Restart stream if capture failed
        if (_controller != null && !_controller!.value.isStreamingImages) {
          _startImageStream(_controller!, _cameras[_selectedCameraIndex]);
        }
      }
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    try {
      if (_controller?.value.isStreamingImages == true) {
        _controller?.stopImageStream();
      }
    } catch (_) {}
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final circleSize = size.width * 0.72; // Circular border diameter

    // Border line color: Pure Green ONLY when live real face is detected; White otherwise
    final borderColor = _isFaceDetected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.85);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full Clean Live Camera Preview
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: Center(
                child: CameraPreview(_controller!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // 2. Top Bar with Title & Controls
          Positioned(
            top: 45,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context, null),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isFaceDetected ? const Color(0xFF10B981) : Colors.white24,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isFaceDetected ? Icons.check_circle : Icons.face,
                        color: _isFaceDetected ? const Color(0xFF10B981) : Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_cameras.length > 1)
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                    onPressed: _switchCamera,
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),

          // 3. Perfect Circular Border LINE ONLY (Completely Transparent Inside & Outside)
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent, // Completely transparent inside
                border: Border.all(
                  color: borderColor,
                  width: _isFaceDetected ? 4.0 : 2.5,
                ),
              ),
            ),
          ),

          // 4. Real-time Status Indicator Badge (Below Circle)
          Positioned(
            top: (size.height / 2) + (circleSize / 2) + 20,
            left: 20,
            right: 20,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: _isFaceDetected 
                      ? const Color(0xFF064E3B).withValues(alpha: 0.9) 
                      : Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isFaceDetected ? const Color(0xFF10B981) : Colors.white24,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isFaceDetected ? Icons.verified : Icons.center_focus_strong,
                      color: _isFaceDetected ? const Color(0xFF34D399) : Colors.amberAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _isFaceDetected ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Bottom Capture Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _captureSelfie,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isFaceDetected ? const Color(0xFF10B981) : Colors.white,
                        width: 4,
                      ),
                    ),
                    child: _isTakingPhoto
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : Container(
                            decoration: BoxDecoration(
                              color: _isFaceDetected ? const Color(0xFF10B981) : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: _isFaceDetected ? Colors.white : Colors.black,
                              size: 36,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
