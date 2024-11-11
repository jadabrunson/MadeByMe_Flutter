import 'dart:convert'; // Import for base64Encode and jsonEncode
import 'dart:io'; // Import for File
import 'package:http/http.dart' as http; // Import for http

class VisionHelper {
  static const String apiKey = 'AIzaSyB22hFvSIxZQEG6kDeQo4zZkNGpqLzNqzE';
  static const double confidenceThreshold = 0.1;
  static const double challengeConfidenceThreshold = 0.1;

  // Method to verify image with Google Vision API
  static Future<Map<String, bool>> verifyImage(File imageFile) async {
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Debug: Print the entire response for inspection
        print('API response: $data');

        // Process the response to determine if it is home-cooked food
        bool isHomeCooked = _isHomeCookedFood(data['responses'][0]);
        bool matchesChallenge = _matchesChallengeTheme(data['responses'][0]);

        print('isHomeCooked: $isHomeCooked, matchesChallenge: $matchesChallenge');

        return {'isVerified': isHomeCooked, 'matchesChallenge': isHomeCooked && matchesChallenge};
      } else {
        print('Failed to connect to Vision API: ${response.statusCode}');
        return {'isVerified': false, 'matchesChallenge': false};
      }
    } catch (e) {
      print('Error verifying image: $e');
      return {'isVerified': false, 'matchesChallenge': false};
    }
  }

  // Determines if the image contains home-cooked food
  static bool _isHomeCookedFood(Map<String, dynamic> response) {
    bool hasFoodLabel = false;

    // Define keywords to identify home-cooked food
    const foodKeywords = [
      "food", "meal", "dish", "cuisine", "plate", "cooking", "homemade", "baked", "kitchen", "fresh", "prepared"
    ];
    const nonHomeCookedKeywords = [
      "restaurant", "fast food", "takeout", "packaged", "brand", "logo"
    ];

    // Check for food-related labels with confidence threshold
    if (response.containsKey('labelAnnotations')) {
      for (var annotation in response['labelAnnotations']) {
        String description = annotation['description'].toLowerCase();
        double confidence = annotation['score'];

        print('Food Label: $description, Confidence: $confidence');

        if (foodKeywords.any((keyword) => description.contains(keyword)) && confidence >= confidenceThreshold) {
          hasFoodLabel = true;
        }

        if (nonHomeCookedKeywords.any((keyword) => description.contains(keyword))) {
          return false; // Immediately return false if non-home-cooked keywords are found
        }
      }
    }

    return hasFoodLabel;
  }

  // Check if the image matches a specific challenge theme with an expanded keyword list and a lower confidence threshold
  static bool _matchesChallengeTheme(Map<String, dynamic> response) {
    // Expanded list of vegan-related keywords for better detection
    const challengeKeywords = [
      "vegan", "plant-based", "vegetable", "tofu", "salad", "fruit", "legume", "bean", "nuts", "grains", "plant protein",
      "vegetarian", "greens", "fiber", "herbs", "root vegetables"
    ];

    if (response.containsKey('labelAnnotations')) {
      for (var annotation in response['labelAnnotations']) {
        String description = annotation['description'].toLowerCase();
        double confidence = annotation['score'];

        // Debugging: Print each label and its confidence
        print('Challenge Label: $description, Confidence: $confidence');

        if (challengeKeywords.any((keyword) => description.contains(keyword)) && confidence >= challengeConfidenceThreshold) {
          print('Challenge theme match found');
          return true; // Only consider it a match if confidence is above the threshold
        }
      }
    }
    return false;
  }
}
