import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class VisionHelper {
  static const String apiKey = 'AIzaSyB22hFvSIxZQEG6kDeQo4zZkNGpqLzNqzE';
  static const double confidenceThreshold = 0.1;
  static const double challengeConfidenceThreshold = 0.1;

  static Future<Map<String, bool>> verifyImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');
      final headers = {"Content-Type": "application/json"};

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

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('API response: $data');

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

  static bool _isHomeCookedFood(Map<String, dynamic> response) {
    bool hasFoodLabel = false;

    const foodKeywords = [
      "food", "meal", "dish", "cuisine", "plate", "cooking", "homemade", "baked", "kitchen", "fresh", "prepared"
    ];
    const nonHomeCookedKeywords = [
      "restaurant", "fast food", "takeout", "packaged", "brand", "logo"
    ];

    if (response.containsKey('labelAnnotations')) {
      for (var annotation in response['labelAnnotations']) {
        String description = annotation['description'].toLowerCase();
        double confidence = annotation['score'];

        print('Food Label: $description, Confidence: $confidence');

        if (foodKeywords.any((keyword) => description.contains(keyword)) && confidence >= confidenceThreshold) {
          hasFoodLabel = true;
        }

        if (nonHomeCookedKeywords.any((keyword) => description.contains(keyword))) {
          return false;
        }
      }
    }

    return hasFoodLabel;
  }

  static bool _matchesChallengeTheme(Map<String, dynamic> response) {
    const challengeKeywords = [
      "vegan", "plant-based", "vegetable", "tofu", "salad", "fruit", "legume", "bean", "nuts", "grains", "plant protein",
      "vegetarian", "greens", "fiber", "herbs", "root vegetables"
    ];

    if (response.containsKey('labelAnnotations')) {
      for (var annotation in response['labelAnnotations']) {
        String description = annotation['description'].toLowerCase();
        double confidence = annotation['score'];

        print('Challenge Label: $description, Confidence: $confidence');

        if (challengeKeywords.any((keyword) => description.contains(keyword)) && confidence >= challengeConfidenceThreshold) {
          print('Challenge theme match found');
          return true;
        }
      }
    }
    return false;
  }
}
