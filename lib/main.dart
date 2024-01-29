import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late List<CameraDescription> cameras;
  late XFile? imageFile;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      await _controller.initialize();
      if (mounted) {
        setState(() {});
      }
    } else {
      // Gérer le cas où aucune caméra n'est disponible
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Aucune caméra disponible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<XFile?> captureImage() async {
    try {
      XFile picture = await _controller.takePicture();
      return picture;
    } catch (e) {
      print("Error capturing image: $e");
      return null;
    }
  }

  Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile;
  }

  Future<String?> processImage(XFile imageFile) async {
    try {
      InputImage inputImage = InputImage.fromFilePath(imageFile.path);
      TextRecognizer textRecognizer = GoogleMlKit.vision.textRecognizer();
      RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print("Error processing image: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Camera App')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  imageFile = await captureImage();
                  if (imageFile != null) {
                    processAndNavigate(imageFile!);
                  } else {
                    // Gérer l'échec de la capture d'image
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Erreur'),
                        content: Text('La capture d\'image a échoué.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text('Prendre une photo'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  XFile? pickedFile = await pickImage();
                  if (pickedFile != null) {
                    processAndNavigate(pickedFile);
                  } else {
                    // Gérer l'échec de la sélection d'image depuis la galerie
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Erreur'),
                        content: Text('La sélection d\'image depuis la galerie a échoué.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text('Sélectionner depuis la galerie'),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  void processAndNavigate(XFile imageFile) async {
    String? extractedText = await processImage(imageFile);
    if (extractedText != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPage(imageFile: imageFile, extractedText: extractedText),
        ),
      );
    } else {
      // Gérer l'échec de l'extraction de texte
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('L\'extraction du texte a échoué.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class CameraPage extends StatelessWidget {
  final XFile? imageFile;
  final String? extractedText;

  CameraPage({required this.imageFile, required this.extractedText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Preview')),
      body: Column(
        children: [
          Image.file(imageFile != null ? File(imageFile!.path) : File('placeholder_path')),
          SizedBox(height: 20),
          Text(extractedText != null ? extractedText! : 'Aucun texte extrait'),
        ],
      ),
    );
  }
}
