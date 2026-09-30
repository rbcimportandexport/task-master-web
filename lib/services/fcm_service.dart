import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class FCMService {
  // TODO: Insert your Firebase Service Account JSON if needed
  static const String _serviceAccountJson = """
{
  "type": "service_account",
  "project_id": "YOUR_PROJECT_ID"
}
""";

  static Future<String?> _getAccessToken() async {
    try {
      if (_serviceAccountJson.contains('YOUR_PROJECT_ID')) {
        return null;
      }
      final accountCredentials = ServiceAccountCredentials.fromJson(_serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      return null;
    }
  }

  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) return;

      const projectId = 'todo-list-app-ef186';
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data?.map((k, v) => MapEntry(k, v.toString())) ?? {},
        },
      };

      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );
    } catch (e) {
      // Ignored for security
    }
  }
}
