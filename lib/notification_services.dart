import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification/message_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  //~ notification permission
  void requestNotificationPermission() async{
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true
    );

    if(settings.authorizationStatus == AuthorizationStatus.authorized){
      //~ used for android 
      // print("user granted permission");
    }else if(settings.authorizationStatus == AuthorizationStatus.provisional){
      //~ used for ios
      // print("user granted provisional permission");
    }else{
      // print("user denied permission parmanently");
      await openAppSettings();
    }
  }

  //~ firebase notification stream listener
  void firebaseInit(BuildContext context){
    FirebaseMessaging.onMessage.listen((message) { 

      RemoteNotification? notification = message.notification ;
      AndroidNotification? android = message.notification!.android ;

      if (kDebugMode) {
        print("notifications title:${notification!.title}");
        print("notifications body:${notification.body}");
        print('count:${android!.count}');
        print('data:${message.data.toString()}');
      }

      if(Platform.isIOS){
        forgroundMessage();
      }

      if(Platform.isAndroid){
        initLocalNotifications(context, message);
        showNotification(message);
      }
    });
  }


  //~ to get current device firebase token 
  Future<String> getDeviceToken() async {
    String? token = await messaging.getToken();
    return token!;
  }

  //~ it will check token expiry and refresh
  void isDeviceTokenRefresh() async {
    messaging.onTokenRefresh.listen((event) { 
      event.toString();
      //do update token in database
    });
  }


  //~ function to initilaize local notification plugin to show notification when app is active
  void initLocalNotifications(BuildContext context, RemoteMessage message) async{
    var androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');

    var darwinInitializationSettings = const DarwinInitializationSettings();

    var initializationSetting = InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSetting,
      onDidReceiveNotificationResponse: (payload) {
        handleNotificationRoute(context, message);
      },
    );
  }

  //~ function to notification when app is active
  Future<void> showNotification(RemoteMessage message) async{

    AndroidNotificationChannel channel = AndroidNotificationChannel(
      Random.secure().nextInt(100000).toString(),
      'High Importance Notification',
      importance: Importance.max,
      showBadge: true ,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('jetsons_doorbell')
    );

    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      channel.id.toString(), 
      channel.name.toString(),
      channelDescription: 'your channel description',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      ticker: 'ticker',
      sound: channel.sound
    );

    DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails
    );

    Future.delayed(
      Duration.zero,
      (){
        flutterLocalNotificationsPlugin.show(
          0, 
          message.notification!.title.toString(), 
          message.notification!.body.toString(), 
          notificationDetails
        );
      }
    );
  }


  //~ handle navigation of notification when app is active (works only on android)
  void handleNotificationRoute(BuildContext context, RemoteMessage message){
    if(message.data['type'] =='notif'){
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => MessageScreen(
            id: message.data['id'] ,
          )));
    }
  }

  //~ for ios working
  Future forgroundMessage() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  //~ handle tap on notification when app is in background or terminated
  Future<void> setupInteractMessage(BuildContext context)async{

    //~ when app is terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if(initialMessage != null){
      handleNotificationRoute(context, initialMessage);
    }


    //~ when app in background
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      handleNotificationRoute(context, event);
    });

  }



}