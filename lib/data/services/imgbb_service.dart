import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for uploading images to ImageBB
///
/// Uses ImageBB API v1 for image hosting.
/// Free tier: 32MB per image, unlimited uploads.
class ImgBBService {
  static const String _apiKey = '3c4395c0c80f4bd2ecb79667fce357aa';
  static const String _baseUrl = 'https://api.imgbb.com/1/upload';

  /// Upload image file to ImageBB
  ///
  /// Returns the public URL of the uploaded image, or null if failed.
  static Future<String?> uploadFile(File imageFile) async {
    try {
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();

      // Convert to base64
      final base64Image = base64Encode(bytes);

      // Get filename
      final filename = imageFile.path.split('/').last;

      return await _upload(base64Image, filename);
    } catch (e) {
      debugPrint('ImgBB: uploadFile error - $e');
      return null;
    }
  }

  /// Upload base64 image to ImageBB
  ///
  /// Returns the public URL of the uploaded image, or null if failed.
  static Future<String?> uploadBase64(String base64Image, {String? filename}) async {
    try {
      return await _upload(base64Image, filename ?? 'upload');
    } catch (e) {
      debugPrint('ImgBB: uploadBase64 error - $e');
      return null;
    }
  }

  /// Internal upload method
  static Future<String?> _upload(String base64Image, String filename) async {
    try {
      final uri = Uri.parse('$_baseUrl?key=$_apiKey');

      final request = http.MultipartRequest('POST', uri)
        ..fields['image'] = base64Image
        ..fields['name'] = filename;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['success'] == true) {
          final url = json['data']['url'] as String?;
          debugPrint('ImgBB: Upload successful - $url');
          return url;
        } else {
          debugPrint('ImgBB: Upload failed - ${json['status']}');
          return null;
        }
      } else {
        debugPrint('ImgBB: HTTP error - ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('ImgBB: _upload error - $e');
      return null;
    }
  }

  /// Delete image from ImageBB (using delete URL)
  static Future<bool> deleteImage(String deleteUrl) async {
    try {
      final response = await http.get(Uri.parse(deleteUrl));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ImgBB: deleteImage error - $e');
      return false;
    }
  }

  /// Get image info from URL
  static Map<String, String> getImageVariants(String baseUrl) {
    // Extract the image ID from URL
    // Example: https://i.ibb.co/abc123/image.png
    final uri = Uri.parse(baseUrl);
    final pathSegments = uri.pathSegments;

    if (pathSegments.length >= 2) {
      final id = pathSegments[pathSegments.length - 2];
      final filename = pathSegments.last;

      return {
        'original': baseUrl,
        'thumb': 'https://i.ibb.co/$id/thumb_$filename',
        'medium': 'https://i.ibb.co/$id/medium_$filename',
      };
    }

    return {'original': baseUrl};
  }
}
