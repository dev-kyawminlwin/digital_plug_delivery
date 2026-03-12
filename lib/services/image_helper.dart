import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery and aggressively compresses it into a Base64 string
  static Future<String?> pickAndCompressImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        // Initial hardware compression
        maxWidth: 600, 
        maxHeight: 600,
        imageQuality: 50, 
      );

      if (file == null) return null;

      final bytes = await file.readAsBytes();
      
      // Secondary software compression to guarantee small payload
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Ensure the image fits within reasonable DB bounds (Firestore max is ~1MB)
      // Usually a 400x400 JPEG at Q50 is under 50KB in Base64
      image = img.copyResize(image, width: 400); 
      
      List<int> compressedBytes = img.encodeJpg(image, quality: 40);
      String base64String = base64Encode(compressedBytes);
      
      return base64String;
    } catch (e) {
      print("Error picking/compressing image: $e");
      return null;
    }
  }
}
