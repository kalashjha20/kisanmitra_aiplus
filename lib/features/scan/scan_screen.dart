import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../../services/connectivity_service.dart';
import '../../services/groq_service.dart';

class ScanScreen extends StatefulWidget {
  final File? imageFile;
  const ScanScreen({super.key, this.imageFile});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {

  File? _image;
  bool _isAnalyzing = false;
  bool _hasOnlineInfo = false;

  // TFLite results
  double confidence = 0.0;
  String diseaseName = "No result";
  String riskLevel = "Low";

  // Groq results
  String description = "";
  List<String> symptoms = [];
  List<String> causes = [];
  List<String> treatment = [];
  List<String> prevention = [];

  late AnimationController _controller;
  late Animation<double> _animation;

  final ImagePicker _picker = ImagePicker();
  Interpreter? _interpreter;
  List<String> labels = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
    _initAll();
  }

  Future<void> _initAll() async {
    await _loadModel();
    await _loadLabels();
    if (widget.imageFile != null) {
      setState(() => _image = widget.imageFile);
      _analyzeImage();
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/plant_model.tflite');
      debugPrint("✅ TFLite Model loaded");
    } catch (e) {
      debugPrint("❌ Model load failed: $e");
    }
  }

  Future<void> _loadLabels() async {
    final jsonString = await rootBundle.loadString('assets/class_names.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    labels = jsonList.map((e) => e.toString()).toList();
    debugPrint("✅ Labels loaded: ${labels.length} classes");
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;
    setState(() => _image = File(picked.path));
    _analyzeImage();
  }

  // MAIN ANALYZE FUNCTION
  Future<void> _analyzeImage() async {
    if (_image == null || _interpreter == null) return;

    setState(() {
      _isAnalyzing = true;
      diseaseName = "Analyzing...";
      confidence = 0.0;
      description = "";
      symptoms = [];
      causes = [];
      treatment = [];
      prevention = [];
      _hasOnlineInfo = false;
    });

    // STEP 1 - Always run TFLite first
    final tfliteResult = await _runTFLite();
    final detectedDisease = tfliteResult['disease'] as String;
    final detectedConfidence = tfliteResult['confidence'] as double;

    setState(() {
      diseaseName = detectedDisease;
      confidence = detectedConfidence;
      riskLevel = confidence > 0.8
          ? "High"
          : confidence > 0.5
          ? "Medium"
          : "Low";
    });

    debugPrint("🧠 TFLite result: $detectedDisease ($detectedConfidence)");

    // STEP 2 - Check internet and get Groq description
    final hasInternet = await ConnectivityService.hasInternet();

    if (hasInternet) {
      debugPrint("🌐 Getting Groq description for: $detectedDisease");
      await _getGroqDescription(detectedDisease);
    } else {
      debugPrint("📴 No internet - showing TFLite result only");
      setState(() {
        description = "Connect to internet for detailed disease information.";
        treatment = [
          "Apply copper-based fungicide",
          "Avoid overhead irrigation",
          "Remove infected leaves",
          "Consult local agricultural expert",
        ];
      });
    }

    setState(() => _isAnalyzing = false);
    _updateAnimation();
  }

  // STEP 1 - TFLite inference
  Future<Map<String, dynamic>> _runTFLite() async {
    final imageBytes = await _image!.readAsBytes();
    final image = img.decodeImage(imageBytes);

    final finalImage = img.copyResize(
      image!,
      width: 160,
      height: 160,
      interpolation: img.Interpolation.linear,
    );

    // MobileNetV2 preprocessing [-1, 1]
    var input = [
      List.generate(160, (y) =>
          List.generate(160, (x) {
            final pixel = finalImage.getPixel(x, y);
            final r = (pixel.r / 127.5) - 1.0;
            final g = (pixel.g / 127.5) - 1.0;
            final b = (pixel.b / 127.5) - 1.0;
            return [r, g, b];
          }))
    ];

    var output = List.generate(1, (_) => List.filled(labels.length, 0.0));
    _interpreter!.run(input, output);

    int predictedIndex = 0;
    double maxScore = output[0][0];
    for (int i = 1; i < output[0].length; i++) {
      if (output[0][i] > maxScore) {
        maxScore = output[0][i];
        predictedIndex = i;
      }
    }

    final cleanName = labels[predictedIndex]
        .replaceAll('___', ' - ')
        .replaceAll('__', ' ')
        .replaceAll('_', ' ');

    return {
      'disease': cleanName,
      'confidence': maxScore,
    };
  }

  // STEP 2 - Groq text description
  Future<void> _getGroqDescription(String detectedDisease) async {
    final result = await GroqService.getDiseaseInfo(detectedDisease);

    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        _hasOnlineInfo = true;
        description = data['description'] ?? "";
        symptoms = List<String>.from(data['symptoms'] ?? []);
        causes = List<String>.from(data['causes'] ?? []);
        treatment = List<String>.from(data['treatment'] ?? []);
        prevention = List<String>.from(data['prevention'] ?? []);
      });
      debugPrint("✅ Groq description received");
    } else {
      debugPrint("⚠️ Groq failed - showing basic treatment");
      setState(() {
        description = "Unable to fetch detailed info. Showing basic guidance.";
        treatment = [
          "Apply copper-based fungicide",
          "Avoid overhead irrigation",
          "Remove infected leaves",
          "Consult local agricultural expert",
        ];
      });
    }
  }

  void _updateAnimation() {
    setState(() {
      _animation = Tween<double>(begin: 0, end: confidence).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
    });
    _controller.forward(from: 0);
  }

  Color _riskColor() {
    switch (riskLevel) {
      case "High": return Colors.red;
      case "Medium": return Colors.orange;
      default: return Colors.green;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "AI Disease Analysis",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Image preview
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 12),

            // Analyzing indicator
            if (_isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 8),
                  Text(
                    "Analyzing leaf...",
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),

            // Results
            if (!_isAnalyzing && _image != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Source badges
                        Row(
                          children: [
                            // TFLite badge - always shown
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.memory,
                                      color: Colors.green, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    "AI Model",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Online/Offline badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _hasOnlineInfo
                                    ? Colors.blue.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _hasOnlineInfo
                                        ? Icons.cloud_done
                                        : Icons.offline_bolt,
                                    color: _hasOnlineInfo
                                        ? Colors.blue
                                        : Colors.orange,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _hasOnlineInfo
                                        ? "Online Details"
                                        : "Offline Mode",
                                    style: TextStyle(
                                      color: _hasOnlineInfo
                                          ? Colors.blue
                                          : Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Disease name
                        Text(
                          diseaseName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Risk badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _riskColor().withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Risk Level: $riskLevel",
                            style: TextStyle(
                              color: _riskColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Confidence bar
                        const Text(
                          "Confidence",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(
                                  value: _animation.value,
                                  minHeight: 10,
                                  backgroundColor: Colors.grey.shade300,
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${(_animation.value * 100).toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          },
                        ),

                        // Description
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "About",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(description),
                        ],

                        // Symptoms
                        if (symptoms.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "Symptoms",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ...symptoms.map((s) => Padding(
                            padding:
                            const EdgeInsets.only(bottom: 4),
                            child: Text("• $s"),
                          )),
                        ],

                        // Causes
                        if (causes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "Causes",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ...causes.map((c) => Padding(
                            padding:
                            const EdgeInsets.only(bottom: 4),
                            child: Text("• $c"),
                          )),
                        ],

                        // Treatment
                        if (treatment.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "Treatment",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ...treatment.asMap().entries.map(
                                (e) => Padding(
                              padding:
                              const EdgeInsets.only(bottom: 4),
                              child:
                              Text("${e.key + 1}. ${e.value}"),
                            ),
                          ),
                        ],

                        // Prevention
                        if (prevention.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "Prevention",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ...prevention.map((p) => Padding(
                            padding:
                            const EdgeInsets.only(bottom: 4),
                            child: Text("• $p"),
                          )),
                        ],

                        const SizedBox(height: 20),

                        // Analyze again button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _analyzeImage,
                            icon: const Icon(Icons.refresh,
                                color: Colors.white),
                            label: const Text(
                              "Analyze Again",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // No image buttons
            if (_image == null) const Spacer(),

            if (_image == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.white),
                    label: const Text(
                      "Camera",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo,
                        color: Colors.white),
                    label: const Text(
                      "Gallery",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}