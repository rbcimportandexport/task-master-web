import 'package:todo_list/services/fcm_service.dart';

void main() async {
  print("Testing FCMService...");
  String fcmToken = "d5dALxirQFuHFXuUIIAbNQ:APA91bFNUOCIdZ1K7YdHHz3q0BYANf50pPMuDsLOZnWXPx2HoM0hPNpUVYgRuOm-pyTjVADEDi9E76OSOzX5dhkrs3v0GFbrZ3SfsY0z44I7bUQpnBntoVo";
  await FCMService.sendPushNotification(
    fcmToken: fcmToken,
    title: "Test from Dart",
    body: "Did it work?",
  );
  print("FCMService call completed.");
}
