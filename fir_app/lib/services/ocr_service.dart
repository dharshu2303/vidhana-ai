import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickFromCamera() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
  }

  Future<XFile?> pickFromGallery() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }

  Future<Map<String, dynamic>> extractText(XFile imageFile) async {
    final file = File(imageFile.path);
    return await ApiService.ocrExtract(file);
  }
}
