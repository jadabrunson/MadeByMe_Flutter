/**
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class VisionHelper {
  static const String apiKey = '458dbfb79da55edfdeb968eccc6a5222265808f4';

  // Method to verify image with Google Vision API
  static Future<bool> verifyImage(File imageFile) async {
    try {
      // Convert the image file to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Define the endpoint and headers
      final url = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');
      final headers = {"Content-Type": "application/json"};

      // Define the request body
      final body = jsonEncode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "LABEL_DETECTION", "maxResults": 10},
              {"type": "OBJECT_LOCALIZATION"},
              {"type": "SAFE_SEARCH_DETECTION"}
            ]
          }
        ]
      });

      // Send the POST request
      final response = await http.post(url, headers: headers, body: body);

      // Check for a successful response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Example logic to verify if the image is a home-cooked meal
        // Customize this logic based on your requirements
        final labels = data['responses'][0]['labelAnnotations'] as List;
        bool isFood = labels.any((label) => label['description'].toLowerCase().contains("food"));
        //bool isSafe = data['responses'][0]['safeSearchAnnotation']['adult'] == 'VERY_UNLIKELY';

        return isFood; //&& isSafe;
      } else {
        print('Failed to connect to Vision API: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error verifying image: $e');
      return false;
    }
  }
}
*/

import 'dart:convert'; // Import for base64Encode and jsonEncode
import 'dart:io'; // Import for File
import 'package:http/http.dart' as http; // Import for http

class VisionHelper {
  static const String apiKey = 'AIzaSyB22hFvSIxZQEG6kDeQo4zZkNGpqLzNqzE';

  // Method to verify image with Google Vision API
  static Future<bool> verifyImage(File imageFile) async {
    try {
      // Convert the image file to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Define the endpoint and headers
      final url = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');
      final headers = {"Content-Type": "application/json"};

      // Define the request body
      final body = jsonEncode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "LABEL_DETECTION", "maxResults": 10},
              {"type": "OBJECT_LOCALIZATION"},
              {"type": "SAFE_SEARCH_DETECTION"}
            ]
          }
        ]
      });

      // Send the POST request
      final response = await http.post(url, headers: headers, body: body);

      // Check for a successful response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Example logic to verify if the image is a home-cooked meal
        // Customize this logic based on your requirements
        final labels = data['responses'][0]['labelAnnotations'] as List;
        bool isFood = labels.any((label) => label['description'].toLowerCase().contains("food"));

        return isFood; // Check your conditions here
      } else {
        print('Failed to connect to Vision API: ${response.statusCode}');
        print('Response body: ${response.body}'); // Debugging line
        return false;
      }
    } catch (e) {
      print('Error verifying image: $e');
      return false;
    }
  }
}

