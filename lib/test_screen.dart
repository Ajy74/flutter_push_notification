import 'package:flutter/material.dart';
import 'package:notification/notification_services.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {

  NotificationServices notificationServices = NotificationServices();

  @override
  void initState() {
    super.initState();
    notificationServices.requestNotificationPermission();
    notificationServices.firebaseInit(context);
    notificationServices.forgroundMessage();
    notificationServices.setupInteractMessage(context);

    notificationServices.getDeviceToken().then((value) {
      print("device token -> $value");
    });
    notificationServices.isDeviceTokenRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Screen",),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),

      body: Container(
        child: Center(child: Text("notification")),
      ),
    );
  }
}